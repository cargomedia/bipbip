require 'bipbip'
require 'bipbip/plugin/memcached'

describe Bipbip::Plugin::Memcached do
  let(:plugin) { Bipbip::Plugin::Memcached.new('memcached', { 'hostname' => 'memcached', 'port' => 11_211 }, 10) }

  it 'should collect data' do
    data = plugin.monitor

    data['cmd_get'].should be_kind_of(Integer)
    data['cmd_set'].should be_kind_of(Integer)
    data['get_misses'].should be_kind_of(Integer)
    data['bytes'].should be_kind_of(Integer)
    data['evictions'].should be_kind_of(Integer)
  end
end
