# encoding: utf-8

require 'bipbip'
require 'bipbip/plugin/systemd_unit'

describe Bipbip::Plugin::SystemdUnit do
  let(:plugin) do
    Bipbip::Plugin::SystemdUnit.new('systemd-unit', { 'unit_name' => 'foo.target' }, 10)
  end

  it 'should collect data' do
    messages = []
    plugin.stub(:log) do |_level, message|
      messages.push(message)
    end

    allow(plugin).to receive(:unit_dependencies).with('foo.target').and_return(%w(unit1 unit2))
    allow(plugin).to receive(:unit_is_active).with('unit1').and_return(true)
    allow(plugin).to receive(:unit_is_failed).with('unit1').and_return(false)

    allow(plugin).to receive(:unit_is_active).with('unit2').and_return(true)
    allow(plugin).to receive(:unit_is_failed).with('unit2').and_return(false)
    plugin.monitor.should eq(
      'all_units_active' => 1,
      'any_unit_stopped' => 0,
      'any_unit_failed' => 0
    )
    messages.should eq([])

    messages = []
    allow(plugin).to receive(:unit_is_active).with('unit2').and_return(false)
    plugin.monitor.should eq(
      'all_units_active' => 0,
      'any_unit_stopped' => 1,
      'any_unit_failed' => 0
    )
    messages.should eq(['foo.target unit stopped: unit2'])

    messages = []
    allow(plugin).to receive(:unit_is_failed).with('unit2').and_return(true)
    plugin.monitor.should eq(
      'all_units_active' => 0,
      'any_unit_stopped' => 0,
      'any_unit_failed' => 1
    )
    messages.should eq(['foo.target unit failed: unit2'])
  end

  it 'should call `systemctl list-dependencies`' do
    result = double('result')
    allow(result).to receive(:stdout).and_return("foo.target\n● foo-dependency1.service\n● foo-dependency1@5000.service\n")

    allow(Komenda).to receive(:run).with(%w(systemctl list-dependencies --plain --full foo.target), fail_on_fail: true).and_return(result)
    plugin.unit_dependencies('foo.target').should eq(%w(foo.target foo-dependency1.service foo-dependency1@5000.service))
  end

  it 'should parse ASCII output of `systemctl list-dependencies`' do
    result = double('result')
    allow(result).to receive(:stdout).and_return("foo.target\n* foo-dependency1.service\n* foo-dependency1@5000.service\n")

    allow(Komenda).to receive(:run).with(%w(systemctl list-dependencies --plain --full foo.target), fail_on_fail: true).and_return(result)
    plugin.unit_dependencies('foo.target').should eq(%w(foo.target foo-dependency1.service foo-dependency1@5000.service))
  end

  it 'should systemctl is-active' do
    result = double('result')
    allow(result).to receive(:success?).and_return(true)

    allow(Komenda).to receive(:run).with(%w(systemctl is-active bar.target)).and_return(result)
    plugin.unit_is_active('bar.target').should eq(true)
  end

  it 'should systemctl is-failed' do
    result = double('result')
    allow(result).to receive(:success?).and_return(true)

    allow(Komenda).to receive(:run).with(%w(systemctl is-failed bar.target)).and_return(result)
    plugin.unit_is_failed('bar.target').should eq(true)
  end
end
