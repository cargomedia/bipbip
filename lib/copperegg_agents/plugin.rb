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
        metric_identifier = metric_identifier(server)
        begin
          until interrupted? do
            time = Time.now
            data = monitor(server)
            CoppereggAgents.logger.debug "#{name} #{metric_identifier}: Data: #{data}"
            CopperEgg::MetricSample.save(name, metric_identifier, Time.now.to_i, data)
            retry_delay = frequency
            interruptible_sleep (frequency - (Time.now - time))
          end
        rescue => e
          CoppereggAgents.logger.error "#{name} #{metric_identifier}: Error getting data: #{e.inspect}"
          interruptible_sleep retry_delay
          retry_delay += frequency if retry_delay < frequency * 10
          retry
        end
      end
    end

    def interrupt
      CoppereggAgents.logger.info "Interrupting plugin process #{Process.pid}"
      @interrupted = true
      interrupt_sleep
    end

    def interrupted?
      @interrupted || Process.getpgid(Process.ppid) != Process.getpgrp
    end

    def name
      self.class.name.split('::').last
    end

    def metric_identifier(server)
      CoppereggAgents.fqdn + '::' + server['hostname']
    end

    def metrics_schema
      raise 'Missing method metrics_schema'
    end

    def monitor(server)
      raise 'Missing method monitor'
    end
  end
end
