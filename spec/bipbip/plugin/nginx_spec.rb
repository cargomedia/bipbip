require 'bipbip'
require 'bipbip/plugin/nginx'
require 'webmock/rspec'

describe Bipbip::Plugin::Nginx do
  let(:plugin) { Bipbip::Plugin::Nginx.new('nginx', {'url' => 'http://localhost/server-status'}, 10) }

  it 'should collect data' do
    response = [
      'Active connections: 11',
      'server accepts handled requests',
      '621436 621436 671531',
      'Reading: 0 Writing: 11 Waiting: 0',
    ].join("\n")
    stub_request(:get, 'http://localhost/server-status').to_return(status: 200, body: response)

    data = plugin.monitor

    data[:connections_requested].should eq(671531)
  end

  it 'should fail on non-200 response' do
    stub_request(:get, 'http://localhost/server-status').to_return(status: 404)

    expect { plugin.monitor }.to raise_error(/Invalid response/)
  end

end
