require 'bipbip'
require 'bipbip/plugin/elasticsearch'

describe Bipbip::Plugin::Elasticsearch do
  let(:plugin) { Bipbip::Plugin::Elasticsearch.new('elasticsearch', { 'url' => 'http://localhost:9200' }, 10) }

  it 'should collect data for 2 nodes cluster' do
    allow(plugin).to receive(:nodes_stats).and_return(
      'nodes' => {
        'node-1' => {
          'indices' => {
            'search' => {
              'query_total' => 5,
              'query_time_in_millis' => 5000,
              'fetch_total' => 10,
              'fetch_time_in_millis' => 10_000
            },
            'filter_cache' => {
              'memory_size_in_bytes' => 1000,
              'evictions' => 100
            },
            'fielddata' => {
              'memory_size_in_bytes' => 9,
              'evictions' => 9
            }
          }
        },
        'node-2' => {
          'indices' => {
            'search' => {
              'query_total' => 15,
              'query_time_in_millis' => 15_000,
              'fetch_total' => 40,
              'fetch_time_in_millis' => 40_000
            },
            'filter_cache' => {
              'memory_size_in_bytes' => 9000,
              'evictions' => 900
            },
            'fielddata' => {
              'memory_size_in_bytes' => 11,
              'evictions' => 11
            }
          }
        }
      }
    )

    data = plugin.monitor

    data['search_query_total'].should eq(20)
    data['search_query_time'].should eq(20)
    data['search_fetch_total'].should eq(50)
    data['search_fetch_time'].should eq(50)
    data['cache_filter_size'].should eq(10_000)
    data['cache_filter_evictions'].should eq(1000)
    data['cache_field_size'].should eq(20)
    data['cache_field_evictions'].should eq(20)
  end
end
