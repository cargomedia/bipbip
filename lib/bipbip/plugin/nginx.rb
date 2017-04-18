module Bipbip
  class Plugin::Nginx < Plugin
    def metrics_schema
      [
        { name: 'connections_accepts', type: 'gauge', unit: 'Connections' },
        { name: 'connections_handled', type: 'gauge', unit: 'Connections' },
        { name: 'connections_dropped', type: 'gauge', unit: 'Connections' },
        { name: 'connections_requests', type: 'gauge', unit: 'Requests' },
        { name: 'active_total', type: 'gauge', unit: 'Connections' },
        { name: 'active_reading', type: 'gauge', unit: 'Connections' },
        { name: 'active_writing', type: 'gauge', unit: 'Connections' },
        { name: 'active_waiting', type: 'gauge', unit: 'Connections' }
      ]
    end

    def monitor
      uri = URI.parse(config['url'])
      response = Net::HTTP.get_response(uri)

      raise "Invalid response from server at #{config['url']}" unless response.code == '200'

      lines = response.body.split(/\r*\n/)
      lines.map(&:strip!)

      data = {}

      stats_connections = match_or_fail(lines[2], /^(\d+) (\d+) (\d+)$/)
      data[:connections_accepts] = stats_connections[1].to_i
      data[:connections_handled] = stats_connections[2].to_i
      data[:connections_dropped] = data[:connections_accepts] - data[:connections_handled]
      data[:connections_requests] = stats_connections[3].to_i

      stats_active_total = match_or_fail(lines[0], /^Active connections: (\d+)$/)
      data[:active_total] = stats_active_total[1].to_i

      stats_active = match_or_fail(lines[3], /^Reading: (\d+) Writing: (\d+) Waiting: (\d+)$/)
      data[:active_reading] = stats_active[1].to_i
      data[:active_writing] = stats_active[2].to_i
      data[:active_waiting] = stats_active[3].to_i

      data
    end

    # @param [String] string
    # @param [Regexp] regexp
    def match_or_fail(string, regexp)
      match_data = regexp.match(string)
      if match_data.nil?
        raise "Data `#{string}` doesn't match pattern `#{regexp}`."
      end
      match_data
    end
  end
end
