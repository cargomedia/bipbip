module CoppereggAgents

  class Plugin

    def initialize()

    end

    def run(server, frequency)
      child_pid = fork {
        trap('INT') { interrupt if !@interrupted }
        trap('TERM') { interrupt if !@interrupted }

        retry_delay = 1
        begin
          while !@interrupted do
            return if @interrupted
            data = {:todo => 12}
            #CopperEgg::MetricSample.save(service, server['name'], Time.now.to_i, data)
            puts "Data for #{name}: #{data}"
            interruptible_sleep frequency
            retry_delay = 1
          end
        rescue => e
          Utils.log "Error gathering #{name} data: #{e.inspect}"
          sleep retry_delay
          retry_delay *= 2 if retry_delay < 100
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
  end
end
