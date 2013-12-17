module Bipbip

  class Plugin::PhpFpm < Plugin

    def metrics_schema
      [
          {:name => 'accepted conn', :type => 'counter', :unit => 'Connections'},
          {:name => 'listen queue', :type => 'gauge', :unit => 'Connections'},
          {:name => 'active processes', :type => 'gauge', :unit => 'Processes'},
      ]
    end

    def monitor
      uri = URI.parse(config['url'])
      response = Net::HTTP.get_response(uri)
      raise "Invalid response from server at #{config['url']}" unless response.code == '200'

      status = JSON.parse(response.body)

      status.reject{|k, v| !metrics_names.include?(k)}
    end
  end
end
