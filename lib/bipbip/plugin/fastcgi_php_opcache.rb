module Bipbip
  class Plugin::FastcgiPhpOpcache < Plugin
    def metrics_schema
      [
        { name: 'free_memory', type: 'gauge', unit: 'b' },
        { name: 'current_wasted_percentage', type: 'gauge', unit: '%' },
        { name: 'num_cached_keys', type: 'gauge', unit: 'Keys' },
        { name: 'hit_rate', type: 'gauge', unit: '%' },
        { name: 'misses', type: 'counter', unit: 'Misses' },
        { name: 'hits', type: 'counter', unit: 'Hits' },
        { name: 'oom_restarts', type: 'counter', unit: 'Restarts' }
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
      @data_previous ||= stats

      stats_memory = stats['memory_usage']
      stats_statistics = stats['opcache_statistics']
      hit_rate = hit_rate(stats)

      @data_previous = stats
      {
        free_memory: stats_memory['free_memory'].to_i,
        current_wasted_percentage: stats_memory['current_wasted_percentage'].to_i,
        num_cached_keys: stats_statistics['num_cached_keys'].to_i,
        hit_rate: hit_rate,
        misses: stats_statistics['misses'].to_i,
        hits: stats_statistics['hits'].to_i,
        oom_restarts: stats_statistics['oom_restarts'].to_i
      }
    end

    private

    def hit_rate(stats)
      current_stats = stats['opcache_statistics']
      previous_stats = @data_previous['opcache_statistics']

      delta_hits = current_stats['hits'].to_f - previous_stats['hits'].to_f
      delta_misses = current_stats['misses'].to_f - previous_stats['misses'].to_f

      delta_total = delta_hits + delta_misses
      hit_rate = delta_total.zero? ? 0 : (delta_hits / delta_total) * 100
      hit_rate.round(2)
    end
  end
end
