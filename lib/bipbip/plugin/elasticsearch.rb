require 'elasticsearch'
class ElasticsearchClient < Elasticsearch::Transport::Client
end

module Bipbip

  class Plugin::Elasticsearch < Plugin

    def metrics_schema
      [
          {:name => 'active_primary_shards', :type => 'gauge', :unit => 'Shards'},
          {:name => 'active_shards', :type => 'gauge', :unit => 'Shards'},
      ]
    end

    def monitor
      client = ElasticsearchClient.new({:hosts => config['hosts']})

      cluster_health = client.cluster.health

      {
          'active_primary_shards' => cluster_health['active_primary_shards'],
          'active_shards' => cluster_health['active_shards'],
      }
    end
  end
end
