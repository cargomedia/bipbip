module CoppereggAgents

  class Plugin
    include InterruptibleSleep

    def initialize
    end

    def run(server, frequency)
      child_pid = fork do
        trap('INT') { interrupt if !@interrupted }
        trap('TERM') { interrupt if !@interrupted }

        retry_delay = frequency
        begin
          until interrupted? do
            data = monitor(server)
            #CopperEgg::MetricSample.save(service, server['name'], Time.now.to_i, data)
            puts "Data for #{name}: #{data}"
            interruptible_sleep frequency
            retry_delay = frequency
          end
        rescue => e
          Utils.log "Error gathering #{name} data: #{e.inspect}"
          interruptible_sleep retry_delay
          retry_delay += frequency if retry_delay < frequency * 10
          retry
        end
      end
    end

    def interrupt
      @interrupted = true
      interrupt_sleep
      Utils.log "Exiting pid #{Process.pid}"
    end

    def interrupted?
      @interrupted
    end

    def name
      self.class
    end

    def configure_metric_group(metric_group)
      raise 'Missing method ensure_metric_group'
    end

    def monitor(server)
      raise 'Missing method monitor'
    end
  end
end
