require 'net/telnet'

module Bipbip
  class Plugin::Coturn < Plugin
    def metrics_schema
      [
        {name : 'total_sessions_count', type : 'gauge', unit : 'Sessions'}
      ]
    end

    def monitor
      coturn = Net::Telnet::new("Host" => config['hostname'] || "localhost",
                                "Port" => config['port'] || 5766)
      current_sessions = coturn.cmd("ps")
      coturn.close

      {
        'total_sessions_count' => current_sessions.match(/Total sessions: (.*)/)[1].to_i
      }
    end
  end
end
