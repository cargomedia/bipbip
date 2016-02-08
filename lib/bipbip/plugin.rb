module Bipbip
  class Plugin
    class MeasurementTimeout < RuntimeError
    end

    include InterruptibleSleep

    attr_accessor :name
    attr_accessor :config
    attr_accessor :frequency
    attr_accessor :tags
    attr_accessor :metric_group

    def self.factory(name, config, frequency, tags, metric_group = nil)
      require "bipbip/plugin/#{Bipbip::Helper.name_to_filename(name)}"
      Plugin.const_get(Bipbip::Helper.name_to_classname(name)).new(name, config, frequency, tags, metric_group)
    end

    # @param [Bipbip::Plugin] plugin
    # @return [Bipbip::Plugin]
    def self.factory_from_plugin(plugin)
      plugin.class.new(plugin.name, plugin.config, plugin.frequency, plugin.tags, plugin.metric_group)
    end

    def initialize(name, config, frequency, tags = nil, metric_group = nil)
      @name = name.to_s
      @config = config.to_hash
      @frequency = frequency.to_f
      @tags = tags.to_a
      @metric_group = (metric_group || name).to_s
    end

    # @param [Array] storages
    def run(storages)
      timeout = frequency * 2
      loop do
        time = Time.now
        Timeout.timeout(timeout, MeasurementTimeout) do
          run_measurement(time, storages)
        end
        interruptible_sleep (frequency - (Time.now - time))
      end
    rescue MeasurementTimeout => e
      log(Logger::ERROR, "Measurement timeout of #{timeout} seconds reached.")
      retry
    rescue StandardError => e
      log_exception(Logger::ERROR, e)
      interruptible_sleep frequency
      retry
    rescue Exception => e
      log_exception(Logger::FATAL, e)
      raise e
    end

    attr_reader :frequency

    def source_identifier
      identifier = Bipbip.fqdn + '::' + metric_group
      unless config.empty?
        identifier += '::' + config.values.first.to_s.gsub(/[^\w]/, '_')
      end
      identifier
    end

    def metrics_names
      metrics_schema.map { |metric| metric[:name] }
    end

    def metrics_schema
      raise 'Missing method metrics_schema'
    end

    def monitor
      raise 'Missing method monitor'
    end

    private

    def run_measurement(time, storages)
      data = monitor
      raise "#{name} #{source_identifier}: Empty data" if data.empty?
      log(Logger::DEBUG, "Data: #{data}")
      storages.each do |storage|
        storage.store_sample(self, time, data)
      end
    end

    def log(severity, message)
      Bipbip.logger.add(severity, message, "#{name} #{source_identifier}")
    end

    def log_exception(severity, exception)
      backtrace = exception.backtrace.map { |line| " #{line}" }.join("\n")
      log(severity, exception.message + "\n" + backtrace)
    end
  end
end
