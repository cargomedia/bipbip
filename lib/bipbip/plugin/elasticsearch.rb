require 'elasticsearch'
class ElasticsearchClient < Elasticsearch::Transport::Client
end

module Bipbip

  class Plugin::Elasticsearch < Plugin

    def metrics_schema
      [
          {:name => 'search_query_total', :type => 'counter', :unit => 'Queries'},
          {:name => 'search_query_time', :type => 'counter', :unit => 'Seconds'},
          {:name => 'search_fetch_total', :type => 'gauge', :unit => 'Fetches'},
          {:name => 'search_fetch_time', :type => 'gauge', :unit => 'Seconds'},

          {:name => 'get_total', :type => 'counter', :unit => 'Gets'},
          {:name => 'get_time', :type => 'counter', :unit => 'Seconds'},
          {:name => 'get_exists_total', :type => 'counter', :unit => 'Exists'},
          {:name => 'get_exists_time', :type => 'counter', :unit => 'Seconds'},
          {:name => 'get_missing_total', :type => 'counter', :unit => 'Missing'},
          {:name => 'get_missing_time', :type => 'counter', :unit => 'Seconds'},

          {:name => 'indexing_index_total', :type => 'counter', :unit => 'Indexes'},
          {:name => 'indexing_index_time', :type => 'counter', :unit => 'Seconds'},
          {:name => 'indexing_delete_total', :type => 'counter', :unit => 'Deletes'},
          {:name => 'indexing_delete_time', :type => 'counter', :unit => 'Seconds'},

          {:name => 'cache_filter_size', :type => 'gauge', :unit => 'b'},
          {:name => 'cache_filter_evictions', :type => 'gauge', :unit => 'b'},
          {:name => 'cache_field_size', :type => 'gauge', :unit => 'b'},
          {:name => 'cache_field_evictions', :type => 'gauge', :unit => 'b'},
      ]
    end

    def monitor
      indices_indexing_stats = total_indices_indexing_stats
      indices_search_stats = total_indices_search_stats
      indices_get_stats = total_indices_get_stats
      indices_cache_stats = total_indices_cache_stats
      {
          'search_query_total' => indices_search_stats[:query_total],
          'search_query_time' => indices_search_stats[:query_time],
          'search_fetch_total' => indices_search_stats[:fetch_total],
          'search_fetch_time' => indices_search_stats[:fetch_time],

          'get_total' => indices_get_stats[:total],
          'get_time' => indices_get_stats[:time],
          'get_exists_total' => indices_get_stats[:exists_total],
          'get_exists_time' => indices_get_stats[:exists_time],
          'get_missing_total' => indices_get_stats[:missing_total],
          'get_missing_time' => indices_get_stats[:missing_time],

          'indexing_index_total' => indices_indexing_stats[:index_total],
          'indexing_index_time' => indices_indexing_stats[:index_time],
          'indexing_delete_total' => indices_indexing_stats[:delete_total],
          'indexing_delete_time' => indices_indexing_stats[:delete_time],

          'cache_filter_size' => indices_cache_stats[:filter_size],
          'cache_filter_evictions' => indices_cache_stats[:filter_evictions],
          'cache_field_size' => indices_cache_stats[:field_size],
          'cache_field_evictions' => indices_cache_stats[:field_evictions],
      }
    end

    private

    def connection
      ElasticsearchClient.new({:host => [config['hostname'], config['port']].join(':')})
    end

    def nodes_status
      connection.nodes.stats
    end

    def total_indices_search_stats
      stats = {:query_total => 0, :query_time => 0, :fetch_total => 0, :fetch_time => 0}
      nodes_status['nodes'].each do |node, status|
        unless status['indices']['search'].nil?
          stats[:query_total] += status['indices']['search']['query_total'].to_i
          stats[:query_time] += status['indices']['search']['query_time_in_millis'].to_i
          stats[:fetch_total] += status['indices']['search']['fetch_total'].to_i
          stats[:fetch_time] += status['indices']['search']['fetch_time_in_millis'].to_i
        end
      end
      stats
    end

    def total_indices_indexing_stats
      stats = {:index_total => 0, :index_time => 0, :delete_total => 0, :delete_time => 0}
      nodes_status['nodes'].each do |node, status|
        unless status['indices']['indexing'].nil?
          stats[:index_total] += status['indices']['indexing']['index_total'].to_i
          stats[:index_time] += status['indices']['indexing']['index_time_in_millis'].to_i
          stats[:delete_total] += status['indices']['indexing']['delete_total'].to_i
          stats[:delete_time] += status['indices']['indexing']['delete_time_in_millis'].to_i
        end
      end
      stats
    end

    def total_indices_cache_stats
      stats = {:filter_size => 0, :filter_evictions => 0, :field_size => 0, :field_evictions => 0}
      nodes_status['nodes'].each do |node, status|
        unless status['indices']['filter_cache'].nil?
          stats[:filter_size] += status['indices']['filter_cache']['memory_size_in_bytes'].to_i
          stats[:filter_evictions] += status['indices']['filter_cache']['evictions'].to_i
          stats[:field_size] += status['indices']['fielddata']['memory_size_in_bytes'].to_i
          stats[:field_evictions] += status['indices']['fielddata']['evictions'].to_i
        end
      end
      stats
    end

    def total_indices_get_stats
      stats = {:total => 0, :time => 0, :exists_total => 0, :exists_time => 0, :missing_total => 0, :missing_time => 0}
      nodes_status['nodes'].each do |node, status|
        unless status['indices']['get'].nil?
          stats[:total] += status['indices']['get']['total'].to_i
          stats[:time] += status['indices']['get']['time_in_millis'].to_i
          stats[:exists_total] += status['indices']['get']['exists_total'].to_i
          stats[:exists_time] += status['indices']['get']['exists_time_in_millis'].to_i
          stats[:missing_total] += status['indices']['get']['missing_total'].to_i
          stats[:missing_time] += status['indices']['get']['missing_time_in_millis'].to_i
        end
      end
      stats
    end

  end
end
