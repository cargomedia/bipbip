module Bipbip

  class Plugin::Nginx < Plugin

    def metrics_schema
      [
          {:name => 'connections_requested', :type => 'ce_counter', :unit => 'Requests'},
      ]
    end

    def monitor
      uri = URI.parse(config['url'])
      response = Net::HTTP.get_response(uri)

      raise "Invalid response from server at #{config['url']}" unless response.code == "200"

      nstats = response.body.split(/\r*\n/)
      connections_requested = nstats[2].lstrip.split(/\s+/)[2].to_i

      {:connections_requested => connections_requested}
    end
  end
end
