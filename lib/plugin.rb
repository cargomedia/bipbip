module CoppereggAgents

  class Plugin

    def initialize()

    end

    def run(server, frequency)
      child_pid = fork {
        trap('INT') { interrupt if !@interrupted }
        trap('TERM') { interrupt if !@interrupted }

        retry_delay = frequency
        begin
          while !@interrupted do
            return if @interrupted
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
      }
    end

    def interrupt
      @interrupted = true
      Utils.log "Exiting pid #{Process.pid}"
    end

    def interruptible_sleep(seconds)
      seconds.times { |i| sleep 1 if !@interrupted }
    end

    def name
      self.class
    end

    def monitor(server)
    end
  end
end
