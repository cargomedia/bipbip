require 'bipbip'
require 'bipbip/plugin/command'

describe Bipbip::Plugin::Command do
  let(:plugin1) { Bipbip::Plugin::Command.new('command', { 'command' => 'command' }, 10) }
  let(:plugin2) { Bipbip::Plugin::Command.new('command', { 'command' => "ruby -e 'puts \"{\\\"file_count\\\": 5}\"'" }, 10) }

  it 'should collect data for simple mode' do
    plugin1.stub(:exec_command).and_return(
      <<DATA
{
  "common_ok": true,
  "router_ok": false,
  "config_ok": true,
  "replica_ok": true,
  "mms_ok": true,
  "cluster_ok": false
}
DATA
    )

    data = plugin1.monitor

    data['common_ok'].should eq(1)
    data['router_ok'].should eq(0)
    data['cluster_ok'].should eq(0)
  end

  it 'should collect data for advanced mode' do
    plugin1.stub(:exec_command).and_return(
      <<DATA
{
  "common_ok": {"value": false, "type": "gauge", "unit": "Boolean"},
  "report_ok": {"value": "true", "type": "gauge", "unit": "Boolean"},
  "router_count":  {"value": 4, "type": "gauge", "unit": "Members"},
  "puppet_runtime":  {"value": 123, "type": "gauge", "unit": "Seconds"},
  "run_errors":  {"value": 199, "type": "counter", "unit": "Integer"}
}
DATA
    )

    data = plugin1.monitor

    data['common_ok'].should eq(0)
    data['report_ok'].should eq(1)
    data['router_count'].should eq(4)
    data['puppet_runtime'].should eq(123)
    data['run_errors'].should eq(199)
  end

  it 'should collect data for executed command' do
    plugin2.metrics_schema
    data = plugin2.monitor

    data['file_count'].should eq(5)
  end
end
