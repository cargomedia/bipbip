require 'bipbip'
require 'bipbip/plugin/memcached'

describe Bipbip::Plugin::Memcached do
  let(:plugin) { Bipbip::Plugin::Memcached.new('memcached', { 'hostname' => 'localhost', 'port' => 11_211 }, 10) }

  it 'should collect data' do
    data = plugin.monitor

    data['cmd_get'].should be_instance_of(Fixnum)
    data['cmd_set'].should be_instance_of(Fixnum)
    data['get_misses'].should be_instance_of(Fixnum)
    data['bytes'].should be_instance_of(Fixnum)
    data['evictions'].should be_instance_of(Fixnum)
  end
end
