module Bipbip
  class Plugin::Network < Plugin
    def metrics_schema
      [
        { name: 'connections_total', type: 'gauge', unit: 'Connections' }
      ]
    end

    def monitor
      tcp_summary = `ss -s | grep '^TCP:'`
      tcp_counters = /^TCP:\s+(\d+) \(estab (\d+), closed (\d+), orphaned (\d+), synrecv (\d+), timewait (\d+)\/(\d+)\), ports (\d+)$/.match(tcp_summary)
      raise "Cannot match ss-output `#{tcp_summary}`" unless tcp_counters

      { connections_total: tcp_counters[1].to_i }
    end
  end
end
