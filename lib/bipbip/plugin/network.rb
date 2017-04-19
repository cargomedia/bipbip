module Bipbip
  class Plugin::Network < Plugin
    def metrics_schema
      [
        { name: 'connections_total', type: 'gauge', unit: 'Connections' },
        { name: 'rx_errors', type: 'counter', unit: 'Errors' },
        { name: 'rx_dropped', type: 'counter', unit: 'Packets' },
        { name: 'tx_errors', type: 'counter', unit: 'Errors' },
        { name: 'tx_dropped', type: 'counter', unit: 'Packets' }
      ]
    end

    def monitor
      tcp_summary = `ss -s | grep '^TCP:'`
      tcp_counters = /^TCP:\s+(\d+) \(estab (\d+), closed (\d+), orphaned (\d+), synrecv (\d+), timewait (\d+)\/(\d+)\), ports (\d+)$/.match(tcp_summary)
      raise "Cannot match ss-output `#{tcp_summary}`" unless tcp_counters
      {
        'connections_total' => tcp_counters[1].to_i,
        'rx_errors' => _statistics_sum('rx_errors'),
        'rx_dropped' => _statistics_sum('rx_dropped'),
        'tx_errors' => _statistics_sum('tx_errors'),
        'tx_dropped' => _statistics_sum('tx_dropped')
      }
    end

    private

    # @param [String] check
    # @return [Integer] Sum of readings for all interfaces
    def _statistics_sum(check)
      _interfaces.reduce(0) do |memo, interface|
        memo + File.read("/sys/class/net/#{interface}/statistics/#{check}".chomp).to_i
      end
    end

    # @return [Array] List of all network interfaces to monitor
    def _interfaces
      interfaces_excluded = config['exclude_interfaces'] || [/lo/, /bond/, /vboxnet/]
      interfaces_found = `ls /sys/class/net/`.split(/\n/)
      interfaces_found.reject { |i| i.match(Regexp.union(interfaces_excluded)) }
    end
  end
end
