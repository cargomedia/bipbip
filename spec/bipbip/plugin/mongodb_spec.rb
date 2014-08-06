require 'bipbip'
require 'bipbip/plugin/mongodb'

describe Bipbip::Plugin::Mongodb do
  let(:plugin) { Bipbip::Plugin::Mongodb.new('mongodb', {'host' => 'mongo.rep1-db2', 'port' => 27018}, 10) }

  it 'should collect data' do
    data = plugin.monitor

    plugin.metrics_schema.each do |metric|
      if metric[:name] == 'globalLock_ratio' then
        data[metric[:name]].should be_instance_of(Float)
      else
        data[metric[:name]].should be_instance_of(Fixnum)
      end
    end
  end
end

describe Bipbip::Plugin::Mongodb do
  let(:plugin) { Bipbip::Plugin::Mongodb.new('mongodb', {'host' => 'expected.failure.config3', 'port' => 22022}, 10) }

  it 'should raise an error' do
    expect { plugin.monitor }.to raise_error
  end
end
