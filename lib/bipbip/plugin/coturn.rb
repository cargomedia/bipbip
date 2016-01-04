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
      coturn = Net::Telnet.new(
        'Host' => config['hostname'] || 'localhost',
        'Port' => config['port'] || 5766
      )
      current_sessions = coturn.cmd('ps')
      coturn.close

      {
        'total_sessions_count' => current_sessions.match(/Total sessions: (.*)/)[1].to_i,
        'total_bitrate_outgoing' => current_sessions.scan(/ s=(\d),/).flatten.map(&:to_i).reduce(:+) * 8,
        'total_bitrate_incoming' => current_sessions.scan(/ r=(\d),/).flatten.map(&:to_i).reduce(:+) * 8
      }
    end
  end
end
