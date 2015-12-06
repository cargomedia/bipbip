require 'bipbip'
require 'bipbip/plugin/memcached'
require 'tempfile'

describe Bipbip::Agent do
  let(:logger_file) { Tempfile.new('bipbip-mock-logger') }
  let(:logger) { Logger.new(logger_file.path) }

  it 'should fail without services' do
    logger = double('logger')
    agent = Bipbip::Agent.new(Bipbip::Config.new([], [], logger))

    logger.should_receive(:info).with('Startup...')
    logger.should_receive(:warn).with('No storages configured')

    expect { agent.run }.to raise_error('No services configured')
  end

  it 'should run in a thread' do
    plugin = Bipbip::Plugin.new('my-plugin', {}, 0.1)
    plugin.stub(:metrics_schema) { [{ name: 'foo', type: 'counter' }] }
    plugin.stub(:source_identifier) { 'my-source' }
    plugin.stub(:monitor) { { foo: 12 } }

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
    plugin.stub(:metrics_schema) { [] }
    plugin.stub(:source_identifier) { 'my-source' }
    plugin.stub(:monitor) { fail 'my-error' }

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
    plugin.stub(:metrics_schema) { [] }
    plugin.stub(:source_identifier) { 'my-source' }
    plugin.stub(:monitor) { sleep(1) }

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
    Bipbip::Plugin.any_instance.stub(:metrics_schema) { [] }
    Bipbip::Plugin.any_instance.stub(:source_identifier) { 'my-source' }
    Bipbip::Plugin.any_instance.stub(:monitor) { fail Exception.new('my-exception') }
    plugin = Bipbip::Plugin.new('my-plugin', {}, 0.1)

    agent = Bipbip::Agent.new(Bipbip::Config.new([plugin], [], logger))
    agent.stub(:interruptible_sleep) {}

    thread = Thread.new { agent.run }
    sleep 0.3

    thread.alive?.should eq(true)
    lines = logger_file.read.lines
    expect(lines.count { |l| l.include?('my-plugin my-source: my-exception') }).to be >= 2
    expect(lines.count { |l| l.include?('Plugin my-plugin with config {} terminated. Restarting...') }).to be >= 2

    thread.exit
  end
end
