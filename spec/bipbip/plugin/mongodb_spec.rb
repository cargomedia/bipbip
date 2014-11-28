require 'bipbip'
require 'bipbip/plugin/mongodb'

describe Bipbip::Plugin::Mongodb do
  let(:plugin) { Bipbip::Plugin::Mongodb.new('mongodb', {'hostname' => 'localhost', 'port' => 27017}, 10) }

  it 'should collect data' do
    plugin.stub(:server_status).and_return(
        {
            'connections' => {
                'current' => 100
            },
            'mem' => {
                'mem_resident' => 1024
            }
        })

    data = plugin.monitor
    data['connections_current'].should be_instance_of(Fixnum)
    data['mem_resident'].should be_instance_of(Fixnum)
  end

  it 'should collect replication lag' do
    plugin.stub(:server_status).and_return(
        {
            'repl' => {
                'secondary' => true
            }
        })

    plugin.stub(:replica_status).and_return(
        {
            'set' => 'rep1',
            'members' => [
                {'stateStr' => 'PRIMARY', 'optime' => BSON::Timestamp.new(1003, 1)},
                {'stateStr' => 'SECONDARY', 'optime' => BSON::Timestamp.new(1000, 1), 'self' => true},
            ]
        })

    data = plugin.monitor
    data['replication_lag'].should eq(3)
  end
end
