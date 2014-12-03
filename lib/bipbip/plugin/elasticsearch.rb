require 'elasticsearch'
class ElasticsearchClient < Elasticsearch::Transport::Client
end

module Bipbip

  class Plugin::Elasticsearch < Plugin

    def metrics_schema
      [
          {:name => 'search_query_total', :type => 'counter', :unit => 'Queries'},
          {:name => 'search_query_time', :type => 'counter', :unit => 'Seconds'},
          {:name => 'search_fetch_total', :type => 'counter', :unit => 'Fetches'},
          {:name => 'search_fetch_time', :type => 'counter', :unit => 'Seconds'},

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
      stats = total_indices_stats
      {
          'search_query_total' => stats[:search][:query_total],
          'search_query_time' => stats[:search][:query_time],
          'search_fetch_total' => stats[:search][:fetch_total],
          'search_fetch_time' => stats[:search][:fetch_time],

          'get_total' => stats[:get][:total],
          'get_time' => stats[:get][:time],
          'get_exists_total' => stats[:get][:exists_total],
          'get_exists_time' => stats[:get][:exists_time],
          'get_missing_total' => stats[:get][:missing_total],
          'get_missing_time' => stats[:get][:missing_time],

          'indexing_index_total' => stats[:indexing][:index_total],
          'indexing_index_time' => stats[:indexing][:index_time],
          'indexing_delete_total' => stats[:indexing][:delete_total],
          'indexing_delete_time' => stats[:indexing][:delete_time],

          'cache_filter_size' => stats[:cache][:filter_size],
          'cache_filter_evictions' => stats[:cache][:filter_evictions],
          'cache_field_size' => stats[:cache][:field_size],
          'cache_field_evictions' => stats[:cache][:field_evictions],
      }
    end

    private

    def connection
      ElasticsearchClient.new({:host => [config['hostname'], config['port']].join(':')})
    end

    def nodes_stats
      connection.nodes.stats
    end

    def total_indices_stats
      stats = {
          :search => {
            :query_total => 0, :query_time => 0, :fetch_total => 0, :fetch_time => 0,
          },
          :indexing => {
              :index_total => 0, :index_time => 0, :delete_total => 0, :delete_time => 0
          },
          :cache => {
              :filter_size => 0, :filter_evictions => 0, :field_size => 0, :field_evictions => 0
          },
          :get => {
              :total => 0, :time => 0, :exists_total => 0, :exists_time => 0, :missing_total => 0, :missing_time => 0
          }
      }
      nodes_stats['nodes'].each do |node, status|
        unless status['indices']['search'].nil?
          stats[:search][:query_total] += status['indices']['search']['query_total'].to_i
          stats[:search][:query_time] += status['indices']['search']['query_time_in_millis'].to_i
          stats[:search][:fetch_total] += status['indices']['search']['fetch_total'].to_i
          stats[:search][:fetch_time] += status['indices']['search']['fetch_time_in_millis'].to_i
        end

        unless status['indices']['indexing'].nil?
          stats[:indexing][:index_total] += status['indices']['indexing']['index_total'].to_i
          stats[:indexing][:index_time] += status['indices']['indexing']['index_time_in_millis'].to_i
          stats[:indexing][:delete_total] += status['indices']['indexing']['delete_total'].to_i
          stats[:indexing][:delete_time] += status['indices']['indexing']['delete_time_in_millis'].to_i
        end

        unless status['indices']['filter_cache'].nil?
          stats[:cache][:filter_size] += status['indices']['filter_cache']['memory_size_in_bytes'].to_i
          stats[:cache][:filter_evictions] += status['indices']['filter_cache']['evictions'].to_i
        end

        unless status['indices']['fielddata'].nil?
          stats[:cache][:field_size] += status['indices']['fielddata']['memory_size_in_bytes'].to_i
          stats[:cache][:field_evictions] += status['indices']['fielddata']['evictions'].to_i
        end

        unless status['indices']['get'].nil?
          stats[:get][:total] += status['indices']['get']['total'].to_i
          stats[:get][:time] += status['indices']['get']['time_in_millis'].to_i
          stats[:get][:exists_total] += status['indices']['get']['exists_total'].to_i
          stats[:get][:exists_time] += status['indices']['get']['exists_time_in_millis'].to_i
          stats[:get][:missing_total] += status['indices']['get']['missing_total'].to_i
          stats[:get][:missing_time] += status['indices']['get']['missing_time_in_millis'].to_i
        end
      end
      stats
    end

  end
end
