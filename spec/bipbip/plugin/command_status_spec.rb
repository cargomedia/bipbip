require 'bipbip'
require 'bipbip/plugin/command_status'

describe Bipbip::Plugin::CommandStatus do
  let(:plugin) { Bipbip::Plugin::CommandStatus.new('foobar', { 'command' => 'exit 42', }, 10) }
  it 'should collect status:0' do
    data = plugin.monitor
    data[:status].should eq(42)
  end
end
