module Bipbip

  class Plugin
    include InterruptibleSleep

    attr_accessor :name
    attr_accessor :config
    attr_accessor :metric_group
    attr_accessor :tags
    attr_accessor :thread

    def self.factory(name, config, frequency, tags, metric_group = nil)
      require "bipbip/plugin/#{Bipbip::Helper.name_to_filename(name)}"
      Plugin::const_get(Bipbip::Helper.name_to_classname(name)).new(name, config, frequency, tags, metric_group)
    end

    def initialize(name, config, frequency, tags = nil, metric_group = nil)
      @name = name.to_s
      @config = config.to_hash
      @frequency = frequency.to_f
      @tags = tags.to_a
      @metric_group = (metric_group || name).to_s
    end

    # @param [Array] storages
    # @return [Thread]
    def run(storages)
      @thread = Thread.new do
        retry_delay = frequency
        begin
          while true
            time = Time.now
            data = monitor
            if data.empty?
              raise "#{name} #{source_identifier}: Empty data"
            end
            log(Logger::DEBUG, "Data: #{data}")
            storages.each do |storage|
              storage.store_sample(self, time, data)
            end
            retry_delay = frequency
            interruptible_sleep (frequency - (Time.now - time))
          end
        rescue => e
          log_exception(Logger::ERROR, e)
          interruptible_sleep retry_delay
          retry_delay += frequency if retry_delay < frequency * 10
          retry
        rescue Exception => e
          log_exception(Logger::FATAL, e)
          raise e
        end
      end
    end

    def frequency
      @frequency
    end

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

    def log(severity, message)
      Bipbip.logger.add(severity, message, "#{name} #{source_identifier}")
    end

    def log_exception(severity, exception)
      backtrace = exception.backtrace.map { |line| " #{line}" }.join("\n")
      log(severity, exception.message + "\n" + backtrace)
    end
  end
end
