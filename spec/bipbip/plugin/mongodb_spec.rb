require 'bipbip'
require 'bipbip/plugin/mongodb'

describe Bipbip::Plugin::Mongodb do
  let(:plugin) { Bipbip::Plugin::Mongodb.new('mongodb', {'hostname' => 'localhost', 'port' => 27017}, 10) }

  it 'should collect data' do
    data = plugin.monitor
    data['connections_current'].should be_instance_of(Fixnum)
    data['mem_resident'].should be_instance_of(Fixnum)
  end
end

describe Bipbip::Plugin::Mongodb do
  let(:plugin) { Bipbip::Plugin::Mongodb.new('mongodb', {'port' => 22022}, 10) }

  it 'should raise an error' do
    expect { plugin.monitor }.to raise_error
  end
end
