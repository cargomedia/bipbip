require 'memcached'
class MemcachedClient < Memcached
end

module CoppereggAgents

  class Plugin::Memcached < Plugin

    def metrics_schema
      [
          {:type => 'ce_counter', :name => 'cmd_get', :position => 0, :label => 'cmd_get'},
          {:type => 'ce_counter', :name => 'cmd_set', :position => 1, :label => 'cmd_set'},
          {:type => 'ce_counter', :name => 'get_misses', :position => 2, :label => 'get_misses'},
          {:type => 'ce_gauge', :name => 'limit_maxbytes', :position => 3, :label => 'limit_maxbytes', :unit => 'b'},
          {:type => 'ce_gauge', :name => 'bytes', :position => 4, :label => 'bytes', :unit => 'b'},
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
