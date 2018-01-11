require 'redis'
class RedisClient < Redis
end

module Bipbip
  class Plugin::Redis < Plugin
    def metrics_schema
      [
        { name: 'total_commands_processed', type: 'counter', unit: 'Commands' },
        { name: 'used_memory', type: 'gauge', unit: 'b' },
        { name: 'used_memory_rss', type: 'gauge', unit: 'b' },
        { name: 'mem_fragmentation_ratio', type: 'gauge', unit: 'Frag' },
        { name: 'connected_clients', type: 'gauge', unit: 'Clients' },
        { name: 'blocked_clients', type: 'gauge', unit: 'BlockedClients' }
      ]
    end

    def float_roundings
      {
        'mem_fragmentation_ratio' => 2
      }
    end

    def monitor
      redis = RedisClient.new(
        host: config['hostname'],
        port: config['port'],
        password: config['password']
      )
      stats = redis.info
      redis.quit

      roundings = float_roundings
      data = {}

      metrics_names.each do |key|
        data[key] = roundings[key].nil? ? stats[key].to_i : stats[key].to_f.round(roundings[key])
      end

      data
    end
  end
end
