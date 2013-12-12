module Bipbip

  class Plugin::Network < Plugin

    def metrics_schema
      [
          {:name => 'connections_total', :type => 'ce_gauge', :unit => 'Connections'},
      ]
    end

    def monitor
      connections = `netstat -tn | wc -l`
      {:connections_total => connections.to_i}
    end
  end
end
