module Bipbip

  class Plugin::Apache2 < Plugin

    def metric_identifier(server)
      Bipbip.fqdn + '::localhost'
    end

    def metrics_schema
      [
          {:name => 'connections_requested', :type => 'ce_counter', :unit => 'Requests'},
      ]
    end

    def monitor(server)
      uri = URI.parse(server['url'])
      response = Net::HTTP.get_response(uri)

      raise "Invalid response from server at #{server['url']}" unless response.code == "200"

      astats = response.body.split(/\r*\n/)

      ainfo = {}
      astats.each do |row|
        name, value = row.split(": ")
        ainfo[name] = value
      end

      {:connections_requested => connections_requested}
    end
  end
end