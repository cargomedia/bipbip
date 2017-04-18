require 'memcached'
class MemcachedClient < Memcached
end

module Bipbip
  class Plugin::Memcached < Plugin
    def metrics_schema
      [
        { name: 'cmd_get', type: 'gauge' },
        { name: 'cmd_set', type: 'gauge' },
        { name: 'get_misses', type: 'gauge' },
        { name: 'bytes', type: 'gauge', unit: 'b' },
        { name: 'evictions', type: 'gauge' }
      ]
    end

    def monitor
      memcached = MemcachedClient.new(config['hostname'].to_s + ':' + config['port'].to_s)
      stats = memcached.stats
      memcached.quit

      data = {}
      metrics_names.each do |key|
        data[key] = stats[key.to_sym].shift.to_i
      end
      data
    end
  end
end
