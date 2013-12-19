module Bipbip

  class Plugin::FastcgiPhpFpm < Plugin

    def metrics_schema
      [
          {:name => 'accepted conn', :type => 'counter', :unit => 'Connections'},
          {:name => 'listen queue', :type => 'gauge', :unit => 'Connections'},
          {:name => 'active processes', :type => 'gauge', :unit => 'Processes'},
      ]
    end

    def monitor
      authority = config['host'].to_s + ':' + config['port'].to_s
      path = config['path'].to_s

      env_backup = ENV.to_hash
      ENV['REQUEST_METHOD'] = 'GET'
      ENV['SCRIPT_NAME'] = path
      ENV['SCRIPT_FILENAME'] = path
      ENV['QUERY_STRING'] = 'json'
      response = `cgi-fcgi -bind -connect #{authority.shellescape} 2>&1`
      ENV.replace(env_backup)

      body = response.split(/\r?\n\r?\n/)[1]
      raise "FastCGI response has no body: #{response}" unless body
      status = JSON.parse(body)

      status.reject{|k, v| !metrics_names.include?(k)}
    end
  end
end
