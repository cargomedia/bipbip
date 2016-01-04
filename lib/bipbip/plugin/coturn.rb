require 'net/telnet'

module Bipbip
  class Plugin::Coturn < Plugin
    def metrics_schema
      [
        {name : 'total_sessions_count', type : 'gauge', unit : 'Sessions'},
        {name : 'total_users_count', type : 'gauge', unit : 'Sessions'},
        {name : 'total_data_send', type : 'gauge', unit : 'Sessions'}
      ]
    end

    def monitor
      localhost = Net::Telnet::new("Host" => config['hostname'] || "localhost",
                                   "Port" => config['port'] || 5766)
      current_sessions = localhost.cmd("ps")
      localhost.close

      # match total sessions
      # loop to find uniq users
      # loop to find send data

      {
        'total_sessions_count' => 0,
        'total_users_count' => 0,
        'total_data_send' => 0
      }
    end
  end
end
