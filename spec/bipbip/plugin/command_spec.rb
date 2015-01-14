require 'bipbip'
require 'bipbip/plugin/command'

describe Bipbip::Plugin::Command do
  let(:plugin) { Bipbip::Plugin::Command.new(
      'exec', {'command' => 'pulsar -c /Users/cargomedia/Projects/pulsar-conf-cargomedia sk production mongo:health:check -s json_print=true -l 0', 'type' => 'gauge', 'unit' => 'Boolean'}, 10) }

  it 'should collect data' do

    plugin.stub(:exec_command).and_return(
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

    data = plugin.monitor

    data['common_ok'].should eq(1)
    data['router_ok'].should eq(0)
    data['cluster_ok'].should eq(0)
  end
end
