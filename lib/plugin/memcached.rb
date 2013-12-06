require 'memcached'
class MemcachedClient < Memcached
end

module CoppereggAgents

  class Plugin::Memcached < Plugin

    def ensure_metric_group

    end

    def monitor(server)
      p server
      cache = MemcachedClient.new(server['hostname'] + ':' + server['port'].to_s)
      stats = cache.stats

      keys = [
          :cmd_get,
          :cmd_set,
          :get_misses,
          :bytes,
          :limit_maxbytes,
      ]

      data = {}
      keys.each { |key|
        data[key] = stats[key].shift.to_i
      }
      data
    end
  end
end
