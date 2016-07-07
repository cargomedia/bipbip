module Bipbip
  class Plugin::Network < Plugin
    def metrics_schema
      metrics = [{ name: 'connections_total', type: 'gauge', unit: 'Connections' }]
      _interfaces.each do |interface|
        _errors.each do |e|
          metrics <<
              { name: "#{interface}_#{e}", type: 'gauge' }
        end
      end
      metrics
    end

    def monitor
      tcp_summary = `ss -s | grep '^TCP:'`
      tcp_counters = /^TCP:\s+(\d+) \(estab (\d+), closed (\d+), orphaned (\d+), synrecv (\d+), timewait (\d+)\/(\d+)\), ports (\d+)$/.match(tcp_summary)
      raise "Cannot match ss-output `#{tcp_summary}`" unless tcp_counters
      data = {}
      data['connections_total'] = tcp_counters[1].to_i
      _interfaces.each do |interface|
        _errors.each do |e|
          data["#{interface}_#{e}"] = File.read("/sys/class/net/#{interface}/statistics/#{e}".chomp).to_i
        end
      end
      data
    end

    private

    def _errors
      %w(rx_errors rx_dropped tx_errors tx_dropped)
    end

    def _interfaces
      config['interfaces'] || []
    end
  end
end
