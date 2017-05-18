require 'bipbip'
require 'bipbip/plugin/network'

describe Bipbip::Plugin::Network do
  let(:plugin1) { Bipbip::Plugin::Network.new('network', { exclude_interfaces: false }, 10) }

  it 'should collect data' do
    data = plugin1.monitor

    data['connections_total'].should be_instance_of(Integer)
    data['rx_errors'].should be_instance_of(Integer)
    data['rx_dropped'].should be_instance_of(Integer)
    data['tx_errors'].should be_instance_of(Integer)
    data['tx_dropped'].should be_instance_of(Integer)
  end
end
