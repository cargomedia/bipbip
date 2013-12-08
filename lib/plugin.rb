module CoppereggAgents

  class Plugin
    include InterruptibleSleep

    def initialize
    end

    def run(server, frequency)
      child_pid = fork do
        ['INT', 'TERM'].each { |sig| trap(sig) {
          Thread.new { interrupt } if !@interrupted
        } }

        retry_delay = frequency
        begin
          until interrupted? do
            data = monitor(server)
            CoppereggAgents.logger.debug "#{name} data: #{data}"
            #CopperEgg::MetricSample.save(service, server['name'], Time.now.to_i, data)
            interruptible_sleep frequency
            retry_delay = frequency
          end
        rescue => e
          CoppereggAgents.logger.error "Cannot get #{name} data: #{e.inspect}"
          interruptible_sleep retry_delay
          retry_delay += frequency if retry_delay < frequency * 10
          retry
        end
      end
    end

    def interrupt
      @interrupted = true
      interrupt_sleep
      CoppereggAgents.logger.info "Interrupting plugin process #{Process.pid}"
    end

    def interrupted?
      @interrupted || Process.getpgid(Process.ppid) != Process.getpgrp
    end

    def name
      self.class.name.split('::').last
    end

    def configure_metric_group(metric_group)
      raise 'Missing method ensure_metric_group'
    end

    def monitor(server)
      raise 'Missing method monitor'
    end
  end
end
