require 'bipbip'
require 'bipbip/plugin/systemd_unit'

describe Bipbip::Plugin::SystemdUnit do
  let(:plugin) do
    Bipbip::Plugin::SystemdUnit.new('systemd-unit', { 'unit_name' => 'foo.target' }, 10)
  end

  it 'should collect data' do
    allow(plugin).to receive(:units).with('foo.target').and_return(%w(unit1 unit2))
    allow(plugin).to receive(:unit_is_running).with('unit1').and_return(true)
    allow(plugin).to receive(:unit_is_running).with('unit2').and_return(false)
    plugin.monitor['all_units_running'].should eq(false)

    allow(plugin).to receive(:unit_is_running).with('unit2').and_return(true)
    plugin.monitor['all_units_running'].should eq(true)
  end
end
