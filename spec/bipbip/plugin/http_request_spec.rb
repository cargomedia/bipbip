require 'spec_helper'
require 'bipbip'
require 'bipbip/plugin/http_request'
require 'webmock/rspec'

describe Bipbip::Plugin::HttpRequest do
  let(:plugin1) { Bipbip::Plugin::HttpRequest.new('http_request', { 'url' => 'http://example.org/stats' }, 10) }
  let(:plugin2) { Bipbip::Plugin::HttpRequest.new('http_request', { 'url' => 'http://example.org/real-stats' }, 10) }

  it 'should collect data for simple mode' do
    response_data = <<DATA
{
  "common_ok": true,
  "router_ok": false,
  "config_ok": true,

  "replica_ok": true,
  "mms_ok": true,
  "cluster_ok": false
}
DATA
    expect(plugin1).to receive(:request).and_return(JSON.parse(response_data))

    data = plugin1.monitor

    data['common_ok'].should eq(1)
    data['router_ok'].should eq(0)
    data['cluster_ok'].should eq(0)
  end

  it 'should collect data for advanced mode' do
    response_data =
      <<DATA
{
  "common_ok": {"value": false, "type": "gauge", "unit": "Boolean"},
  "report_ok": {"value": "true", "type": "gauge", "unit": "Boolean"},
  "router_count":  {"value": 4, "type": "gauge", "unit": "Members"},
  "puppet_runtime":  {"value": 123, "type": "gauge", "unit": "Seconds"},
  "run_errors":  {"value": 199, "type": "counter", "unit": "Integer"}
}
DATA
    expect(plugin1).to receive(:request).and_return(JSON.parse(response_data))

    data = plugin1.monitor

    data['common_ok'].should eq(0)
    data['report_ok'].should eq(1)
    data['router_count'].should eq(4)
    data['puppet_runtime'].should eq(123)
    data['run_errors'].should eq(199)
  end

  it 'should be able to make request' do
    json_data = '{"item":"value","item_nested":{"subitem":"value"}}'

    stub_request(:get, 'http://example.org/real-stats').to_return(status: 200, body: json_data)
    json_data = plugin2.request
    json_data['item'].should eq('value')
  end
end
