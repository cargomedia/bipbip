require 'bipbip'
require 'bipbip/plugin/monit'

describe Bipbip::Plugin::Monit do
  let(:plugin) {
    Bipbip::Plugin::Monit.new('monit', {'host' => "10.10.20.2", 'auth' => false}, 10)
  }

  it 'should collect data' do
    data = plugin.monitor

    data['Running'].should be_instance_of(Fixnum)
    data['All_Services_ok'].should be_instance_of(Fixnum)
  end
end
