module Bipbip

  class Plugin
    include InterruptibleSleep

    attr_accessor :name
    attr_accessor :config
    attr_accessor :metric_group
    attr_accessor :pid

    def self.factory(name, config, frequency, metric_group = nil)
      require "bipbip/plugin/#{Bipbip::Helper.name_to_filename(name)}"
      Plugin::const_get(Bipbip::Helper.name_to_classname(name)).new(name, config, frequency, metric_group)
    end

    def initialize(name, config, frequency, metric_group = nil)
      @name = name.to_s
      @config = config.to_hash
      @frequency = frequency.to_f
      @metric_group = (metric_group || name).to_s
    end

    def run(storages)
      @pid = fork do
        ['INT', 'TERM'].each { |sig| trap(sig) {
          Thread.new { interrupt } if !@interrupted
        } }

        retry_delay = frequency
        begin
          until interrupted? do
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
          log(Logger::ERROR, e.message)
          interruptible_sleep retry_delay
          retry_delay += frequency if retry_delay < frequency * 10
          retry
        rescue Exception => e
          log(Logger::FATAL, e.message)
          raise e
        end
      end
    end

    def interrupt
      log(Logger::INFO, "Interrupting plugin process #{Process.pid}")
      @interrupted = true
      interrupt_sleep
    end

    def interrupted?
      @interrupted || Process.getpgid(Process.ppid) != Process.getpgrp
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
  end
end
