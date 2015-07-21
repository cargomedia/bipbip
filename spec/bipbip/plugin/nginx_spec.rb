require 'bipbip'
require 'bipbip/plugin/nginx'
require 'webmock/rspec'

describe Bipbip::Plugin::Nginx do

  before(:all) do
    WebMock.enable!
  end

  after(:all) do
    WebMock.disable!
  end

  let(:plugin) { Bipbip::Plugin::Nginx.new('nginx', {'url' => 'http://localhost/server-status'}, 10) }

  it 'should collect data' do
    response = [
      'Active connections: 11',
      'server accepts handled requests',
      '621436 621434 671531',
      'Reading: 1 Writing: 7 Waiting: 3',
    ].join("\n")
    stub_request(:get, 'http://localhost/server-status').to_return(status: 200, body: response)

    data = plugin.monitor

    data[:connections_accepts].should eq(621436)
    data[:connections_handled].should eq(621434)
    data[:connections_dropped].should eq(2)
    data[:connections_requests].should eq(671531)

    data[:active_total].should eq(11)
    data[:active_reading].should eq(1)
    data[:active_writing].should eq(7)
    data[:active_waiting].should eq(3)
  end

  it 'should fail on non-200 response' do
    stub_request(:get, 'http://localhost/server-status').to_return(status: 404)

    expect { plugin.monitor }.to raise_error(/Invalid response/)
  end

  it 'should fail on unexpected response' do
    stub_request(:get, 'http://localhost/server-status').to_return(status: 200, body: 'foo')

    expect { plugin.monitor }.to raise_error(/doesn't match pattern/)
  end

end
