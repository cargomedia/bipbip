require 'net/telnet'

module Bipbip
  class Plugin::Coturn < Plugin
    def metrics_schema
      [
        { name: 'total_sessions_count', type: 'gauge', unit: 'Sessions' },
        { name: 'total_bitrate_outgoing', type: 'gauge', unit: 'b/s' },
        { name: 'total_bitrate_incoming', type: 'gauge', unit: 'b/s' }
      ]
    end

    def monitor
      data = _fetch_session_data

      begin
        metrics_data = {
          'total_sessions_count' => data.match(/Total sessions: (.*)/)[1].to_i,
          'total_bitrate_outgoing' => (data.scan(/ s=(\d+),/).flatten.map(&:to_i).reduce(:+) || 0) * 8,
          'total_bitrate_incoming' => (data.scan(/ r=(\d+),/).flatten.map(&:to_i).reduce(:+) || 0) * 8
        }
      rescue => e
        raise("Cannot prepare metrics for malformed response: `#{data}`. Error: `#{e.message}`")
      end

      metrics_data
    end

    private

    def _fetch_session_data
      coturn = Net::Telnet.new(
        'Host' => config['hostname'] || 'localhost',
        'Port' => config['port'] || 5766
      )
      response = coturn.cmd('ps')
      coturn.close

      response
    end
  end
end
