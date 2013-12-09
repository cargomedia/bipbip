require 'memcached'
class MemcachedClient < Memcached
end

module CoppereggAgents

  class Plugin::Memcached < Plugin

    def metrics_schema
      [
          {:name => 'cmd_get', :type => 'ce_counter'},
          {:name => 'cmd_set', :type => 'ce_counter'},
          {:name => 'get_misses', :type => 'ce_counter'},
          {:name => 'limit_maxbytes', :type => 'ce_gauge', :unit => 'b'},
          {:name => 'bytes', :type => 'ce_gauge', :unit => 'b'},
      ]
    end

    def monitor(server)
      cache = MemcachedClient.new(server['hostname'] + ':' + server['port'].to_s)
      stats = cache.stats

      data = {}
      metrics_names.each do |key|
        data[key] = stats[key.to_sym].shift.to_i
      end
      data
    end
  end
end
