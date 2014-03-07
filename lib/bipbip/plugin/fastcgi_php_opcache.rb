module Bipbip

  class Plugin::FastcgiPhpOpcache < Plugin

    def metrics_schema
      [
          {:name => 'free_memory', :type => 'gauge', :unit => 'b'},
          {:name => 'current_wasted_percentage', :type => 'gauge', :unit => '%'},
          {:name => 'num_cached_keys', :type => 'gauge', :unit => 'Keys'},
          {:name => 'opcache_hit_rate', :type => 'gauge', :unit => 'Hits'},
      ]
    end

    def monitor
      authority = config['host'].to_s + ':' + config['port'].to_s
      path = File.join(Bipbip::Helper.data_path, 'php-opcache-status.php')

      env_backup = ENV.to_hash
      ENV['REQUEST_METHOD'] = 'GET'
      ENV['SCRIPT_NAME'] = File.basename(path)
      ENV['SCRIPT_FILENAME'] = path
      response = `cgi-fcgi -bind -connect #{authority.shellescape} 2>&1`
      ENV.replace(env_backup)

      body = response.split(/\r?\n\r?\n/)[1]
      raise "FastCGI response has no body: #{response}" unless body
      stats = JSON.parse(body)

      stats_memory = stats['memory_usage']
      stats_statistics = stats['opcache_statistics']
      {
          :free_memory => stats_memory['free_memory'].to_i,
          :current_wasted_percentage => stats_memory['current_wasted_percentage'].to_i,
          :num_cached_keys => stats_statistics['num_cached_keys'].to_i,
          :opcache_hit_rate => stats_statistics['opcache_hit_rate'].to_i,
      }
    end
  end
end
