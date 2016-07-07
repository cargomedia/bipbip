require 'bipbip'
require 'bipbip/plugin/network'

describe Bipbip::Plugin::Network do
  let(:plugin1) { Bipbip::Plugin::Network.new('network', { 'interfaces' => ['eth0'] }, 10) }

  it 'should collect data' do
    data = plugin1.monitor

    data['connections_total'].should be_instance_of(Fixnum)
    data['eth0_rx_errors'].should be_instance_of(Fixnum)
    data['eth0_rx_dropped'].should be_instance_of(Fixnum)
    data['eth0_tx_errors'].should be_instance_of(Fixnum)
    data['eth0_tx_dropped'].should be_instance_of(Fixnum)
  end
end
