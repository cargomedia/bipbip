require 'memcached'
class MemcachedClient < Memcached
end

module CoppereggAgents

  class Plugin::Memcached < Plugin

    def configure_metric_group(metric_group)
      metric_group.metrics = []
      metric_group.metrics << {:type => "ce_counter", :name => "cmd_get", :position => 0, :label => "cmd_get"}
      metric_group.metrics << {:type => "ce_counter", :name => "cmd_set", :position => 1, :label => "cmd_set"}
      metric_group.metrics << {:type => "ce_counter", :name => "get_misses", :position => 2, :label => "get_misses"}
      metric_group.metrics << {:type => "ce_gauge", :name => "limit_maxbytes", :position => 3, :label => "limit_maxbytes", :unit => "b"}
      metric_group.metrics << {:type => "ce_gauge", :name => "bytes", :position => 4, :label => "bytes", :unit => "b"}
      metric_group.save
    end

    def monitor(server)
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
      keys.each do |key|
        data[key] = stats[key].shift.to_i
      end
      data
    end
  end
end
