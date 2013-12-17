require 'redis'
class RedisClient < Redis
end

module Bipbip

  class Plugin::Redis < Plugin

    def metrics_schema
      [
          {:name => 'total_commands_processed', :type => 'counter', :unit => 'Commands'},
          {:name => 'used_memory', :type => 'gauge', :unit => 'b'},
      ]
    end

    def monitor
      redis = RedisClient.new(
          :host => config['hostname'],
          :port => config['port']
      )
      stats = redis.info
      redis.quit

      data = {}
      metrics_names.each do |key|
        data[key] = stats[key].to_i
      end
      data
    end
  end
end
