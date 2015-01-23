require 'bipbip'
require 'bipbip/plugin/mongodb'

describe Bipbip::Plugin::Mongodb do
  let(:plugin) { Bipbip::Plugin::Mongodb.new('mongodb', {'hostname' => 'localhost', 'port' => 27017}, 10) }

  it 'should collect data' do
    plugin.stub(:fetch_server_status).and_return(
        {
            'connections' => {
                'current' => 100
            },
            'mem' => {
                'resident' => 1024
            }
        })

    plugin.stub(:fetch_slow_queries_status).and_return(
        {
            'total_count' => 12,
            'total_time' => 11.55
        }
    )

    data = plugin.monitor
    data['connections_current'].should eq(100)
    data['mem_resident'].should eq(1024)
    data['slow_queries_count'].should eq(12)
    data['slow_queries_time_total'].should eq(11.55)
  end

  it 'should collect replication lag' do
    plugin.stub(:fetch_server_status).and_return(
        {
            'repl' => {
                'secondary' => true
            }
        })

    plugin.stub(:fetch_replica_status).and_return(
        {
            'set' => 'rep1',
            'members' => [
                {'stateStr' => 'PRIMARY', 'optime' => BSON::Timestamp.new(1000, 1)},
                {'stateStr' => 'SECONDARY', 'optime' => BSON::Timestamp.new(1003, 1), 'self' => true},
            ]
        })

    plugin.stub(:fetch_slow_queries_status).and_return(
        {
            'total_count' => 0,
            'total_time' => 0
        }
    )

    data = plugin.monitor
    data['replication_lag'].should eq(3)
  end

end
