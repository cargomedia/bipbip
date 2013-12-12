module Bipbip

  class Plugin
    include InterruptibleSleep

    attr_accessor :name
    attr_accessor :config

    def self.factory(name, config, frequency)
      require "bipbip/plugin/#{Bipbip::Helper.name_to_filename(name)}"
      Plugin::const_get(Bipbip::Helper.name_to_classname(name)).new(name, config, frequency)
    end

    def initialize(name, config, frequency)
      @name = name.to_s
      @config = config.to_h
      @frequency = frequency.to_i
    end

    def run(storages)
      child_pid = fork do
        ['INT', 'TERM'].each { |sig| trap(sig) {
          Thread.new { interrupt } if !@interrupted
        } }

        retry_delay = frequency
        begin
          until interrupted? do
            time = Time.now
            data = monitor
            if data.empty?
              raise "#{name} #{metric_identifier}: Empty data"
            end
            Bipbip.logger.debug "#{name} #{metric_identifier}: Data: #{data}"
            storages.each do |storage|
              storage.store_sample(self, time, data)
            end
            retry_delay = frequency
            interruptible_sleep (frequency - (Time.now - time))
          end
        rescue => e
          Bipbip.logger.error "#{name} #{metric_identifier}: Error getting data: #{e.message}"
          interruptible_sleep retry_delay
          retry_delay += frequency if retry_delay < frequency * 10
          retry
        end
      end
    end

    def interrupt
      Bipbip.logger.info "Interrupting plugin process #{Process.pid}"
      @interrupted = true
      interrupt_sleep
    end

    def interrupted?
      @interrupted || Process.getpgid(Process.ppid) != Process.getpgrp
    end

    def frequency
      @frequency
    end

    def metric_identifier
      identifier = Bipbip.fqdn
      unless config.empty?
        identifier += '::' + config.values.first.to_s
      end
      identifier
    end

    def metrics_names
      metrics_schema.map {|metric| metric[:name] }
    end

    def metrics_schema
      raise 'Missing method metrics_schema'
    end

    def monitor
      raise 'Missing method monitor'
    end
  end
end
