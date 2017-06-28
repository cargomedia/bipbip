require 'elasticsearch'
class ElasticsearchClient < Elasticsearch::Transport::Client
end

module Bipbip
  class Plugin::Elasticsearch < Plugin
    def metrics_schema
      [
        { name: 'store_size', type: 'gauge', unit: 'b' },
        { name: 'docs_count', type: 'gauge', unit: 'Docs' },
        { name: 'docs_deleted', type: 'gauge', unit: 'Deleted' },
        { name: 'segments_count', type: 'gauge', unit: 'Segments' },

        { name: 'search_query_total', type: 'counter', unit: 'Queries' },
        { name: 'search_query_time', type: 'counter', unit: 'Seconds' },
        { name: 'search_fetch_total', type: 'counter', unit: 'Fetches' },
        { name: 'search_fetch_time', type: 'counter', unit: 'Seconds' },

        { name: 'get_total', type: 'counter', unit: 'Gets' },
        { name: 'get_time', type: 'counter', unit: 'Seconds' },
        { name: 'get_exists_total', type: 'counter', unit: 'Exists' },
        { name: 'get_exists_time', type: 'counter', unit: 'Seconds' },
        { name: 'get_missing_total', type: 'counter', unit: 'Missing' },
        { name: 'get_missing_time', type: 'counter', unit: 'Seconds' },

        { name: 'indexing_index_total', type: 'counter', unit: 'Indexes' },
        { name: 'indexing_index_time', type: 'counter', unit: 'Seconds' },
        { name: 'indexing_delete_total', type: 'counter', unit: 'Deletes' },
        { name: 'indexing_delete_time', type: 'counter', unit: 'Seconds' },

        { name: 'cache_filter_size', type: 'gauge', unit: 'b' },
        { name: 'cache_filter_evictions', type: 'gauge', unit: 'b' },
        { name: 'cache_field_size', type: 'gauge', unit: 'b' },
        { name: 'cache_field_evictions', type: 'gauge', unit: 'b' }
      ]
    end

    def monitor
      @stats = nil
      {
        'store_size' => stats_sum(%w(indices store size_in_bytes)),
        'docs_count' => stats_sum(%w(indices docs count)),
        'docs_deleted' => stats_sum(%w(indices docs deleted)),
        'segments_count' => stats_sum(%w(indices segments count)),

        'search_query_total' => stats_sum(%w(indices search query_total)),
        'search_query_time' => stats_sum(%w(indices search query_time_in_millis)) / 1000,
        'search_fetch_total' => stats_sum(%w(indices search fetch_total)),
        'search_fetch_time' => stats_sum(%w(indices search fetch_time_in_millis)) / 1000,

        'get_total' => stats_sum(%w(indices get total)),
        'get_time' => stats_sum(%w(indices get time_in_millis)) / 1000,
        'get_exists_total' => stats_sum(%w(indices get exists_total)),
        'get_exists_time' => stats_sum(%w(indices get exists_time_in_millis)) / 1000,
        'get_missing_total' => stats_sum(%w(indices get missing_total)),
        'get_missing_time' => stats_sum(%w(indices get missing_time_in_millis)) / 1000,

        'indexing_index_total' => stats_sum(%w(indices indexing index_total)),
        'indexing_index_time' => stats_sum(%w(indices indexing index_time_in_millis)) / 1000,
        'indexing_delete_total' => stats_sum(%w(indices indexing delete_total)),
        'indexing_delete_time' => stats_sum(%w(indices indexing delete_time_in_millis)) / 1000,

        'cache_filter_size' => stats_sum(%w(indices filter_cache memory_size_in_bytes)),
        'cache_filter_evictions' => stats_sum(%w(indices filter_cache evictions)),
        'cache_field_size' => stats_sum(%w(indices fielddata memory_size_in_bytes)),
        'cache_field_evictions' => stats_sum(%w(indices fielddata evictions))
      }
    end

    private

    def connection
      ElasticsearchClient.new(host: [config['hostname'], config['port']].join(':'))
    end

    def nodes_stats
      connection.nodes.stats(node_id: '_local')
    end

    def stats_sum(keys)
      sum = 0
      (@stats ||= nodes_stats)['nodes'].each do |_node, stats|
        sum += keys.inject(stats) { |a, e| a.is_a?(Hash) && !a[e].nil? ? a[e] : 0 }
      end
      sum
    end
  end
end
