require 'spec_helper'
require 'bipbip'
require 'bipbip/plugin/memcached'
require 'tempfile'

describe Bipbip::Agent do
  let(:logger_file) { Tempfile.new('bipbip-mock-logger') }
  let(:logger) { Logger.new(logger_file.path) }

  it 'should fail without services' do
    logger = double('logger')
    agent = Bipbip::Agent.new(Bipbip::Config.new([], [], logger))

    expect(logger).to receive(:info).with('Startup...')
    expect(logger).to receive(:warn).with('No storages configured')

    expect { agent.run }.to raise_error('No services configured')
  end

  it 'should run in a thread' do
    plugin = Bipbip::Plugin.new('my-plugin', {}, 0.1)
    allow(plugin).to receive(:metrics_schema).and_return([{ name: 'foo', type: 'counter' }])
    allow(plugin).to receive(:source_identifier).and_return('my-source')
    allow(plugin).to receive(:monitor).and_return(foo: 12)

    agent = Bipbip::Agent.new(Bipbip::Config.new([plugin], [], logger))

    thread = Thread.new { agent.run }
    sleep 0.3

    thread.alive?.should eq(true)
    lines = logger_file.read.lines
    expect(lines.count { |l| l.include?('my-plugin my-source: Data: {:foo=>12}') }).to be >= 2

    thread.exit
  end

  it 'should log plugin errors and retry' do
    plugin = Bipbip::Plugin.new('my-plugin', {}, 0.1)
    allow(plugin).to receive(:metrics_schema).and_return([])
    allow(plugin).to receive(:source_identifier).and_return('my-source')
    allow(plugin).to receive(:monitor).and_raise('my-error')

    agent = Bipbip::Agent.new(Bipbip::Config.new([plugin], [], logger))

    thread = Thread.new { agent.run }
    sleep 0.3

    thread.alive?.should eq(true)
    lines = logger_file.read.lines
    expect(lines.count { |l| l.include?('my-plugin my-source: my-error') }).to be >= 2
    expect(lines.count { |l| l.include?('Plugin my-plugin with config {} terminated. Restarting...') }).to eq(0)

    thread.exit
  end

  it 'should log plugin timeouts and retry' do
    plugin = Bipbip::Plugin.new('my-plugin', {}, 0.1)
    allow(plugin).to receive(:metrics_schema).and_return([])
    allow(plugin).to receive(:source_identifier).and_return('my-source')
    allow(plugin).to receive(:monitor) { sleep(1) }

    agent = Bipbip::Agent.new(Bipbip::Config.new([plugin], [], logger))

    thread = Thread.new { agent.run }
    sleep 0.5

    thread.alive?.should eq(true)
    lines = logger_file.read.lines
    expect(lines.count { |l| l.include?('my-plugin my-source: Measurement timeout of 0.2 seconds reached.') }).to be >= 2
    expect(lines.count { |l| l.include?('Plugin my-plugin with config {} terminated. Restarting...') }).to eq(0)

    thread.exit
  end

  it 'should log plugin exceptions and restart' do
    allow_any_instance_of(Bipbip::Plugin).to receive(:metrics_schema).and_return([])
    allow_any_instance_of(Bipbip::Plugin).to receive(:source_identifier).and_return('my-source')
    allow_any_instance_of(Bipbip::Plugin).to receive(:monitor).and_raise(Exception.new('my-exception'))
    plugin = Bipbip::Plugin.new('my-plugin', {}, 0.1)

    agent = Bipbip::Agent.new(Bipbip::Config.new([plugin], [], logger))
    allow(agent).to receive(:interruptible_sleep)

    thread = Thread.new { agent.run }
    sleep 0.3

    thread.alive?.should eq(true)
    lines = logger_file.read.lines
    expect(lines.count { |l| l.include?('my-plugin my-source: my-exception') }).to be >= 2
    expect(lines.count { |l| l.include?('Plugin my-plugin with config {} terminated. Restarting...') }).to be >= 2

    thread.exit
  end
end
