#encoding: utf-8

require 'bipbip'
require 'bipbip/plugin/systemd_unit'

describe Bipbip::Plugin::SystemdUnit do
  let(:plugin) do
    Bipbip::Plugin::SystemdUnit.new('systemd-unit', { 'unit_name' => 'foo.target' }, 10)
  end

  it 'should collect data' do
    allow(plugin).to receive(:unit_dependencies).with('foo.target').and_return(%w(unit1 unit2))
    allow(plugin).to receive(:unit_is_active).with('unit1').and_return(true)
    allow(plugin).to receive(:unit_is_active).with('unit2').and_return(false)
    plugin.monitor['all_units_running'].should eq(false)

    allow(plugin).to receive(:unit_is_active).with('unit2').and_return(true)
    plugin.monitor['all_units_running'].should eq(true)
  end

  it 'should systemctl list-dependencies' do
    result = double('result')
    allow(result).to receive(:stdout).and_return("foo.target\n● foo-dependency1.service\n● foo-dependency1@5000.service\n")

    allow(Komenda).to receive(:run).with(["systemctl", "list-dependencies", "--plain", "--full", "foo.target"]).and_return(result)
    plugin.unit_dependencies('foo.target').should eq(%w(foo.target foo-dependency1.service foo-dependency1@5000.service))
  end

  it 'should systemctl is-active' do
    result = double('result')
    allow(result).to receive(:success?).and_return(true)

    allow(Komenda).to receive(:run).with(["systemctl", "is-active", "bar.target"]).and_return(result)
    plugin.unit_is_active('bar.target').should eq(true)
  end
end
