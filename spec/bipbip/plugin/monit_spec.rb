require 'bipbip'
require 'bipbip/plugin/monit'

describe Bipbip::Plugin::Monit do
  let(:plugin) do
    Bipbip::Plugin::Monit.new('monit', {}, 10)
  end

  it 'should collect data' do
    status_service1 = double('service1')
    allow(status_service1).to receive(:monitor).and_return(Bipbip::Plugin::Monit::MONITOR_YES)
    allow(status_service1).to receive(:status).and_return('0')

    status_service2 = double('service2')
    allow(status_service2).to receive(:monitor).and_return(Bipbip::Plugin::Monit::MONITOR_INIT)
    allow(status_service2).to receive(:status).and_return('4608')

    status = double('status')
    allow(status).to receive(:get).and_return(true)
    allow(status).to receive(:services).and_return([status_service1, status_service2])

    ::Monit::Status.stub(:new).and_return(status)

    data = plugin.monitor

    data['Running'].should eq(1)
    data['All_Services_ok'].should eq(0)
  end
end
