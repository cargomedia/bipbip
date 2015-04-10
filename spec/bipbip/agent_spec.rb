require 'bipbip'
require 'bipbip/plugin/memcached'
require 'tempfile'

describe Bipbip::Agent do
  let(:agent) { Bipbip::Agent.new }

  it 'should fail without services' do
    Bipbip.logger = double('logger')

    Bipbip.logger.should_receive(:info).with('Startup...')
    Bipbip.logger.should_receive(:warn).with('No storages configured')

    expect { agent.run }.to raise_error('No services configured')

    Bipbip.logger = nil
  end

  it 'should run in a thread' do
    logger_file = Tempfile.new('bipbip-mock-logger')
    Bipbip.logger = Logger.new(logger_file.path)

    plugin = Bipbip::Plugin.new('my-plugin', {}, 0.1)
    plugin.stub(:metrics_schema) { [{:name => 'foo', :type => 'counter'}] }
    plugin.stub(:source_identifier) { 'my-source' }
    plugin.stub(:monitor) { {:foo => 12} }

    agent.plugins = [plugin]

    thread = Thread.new { agent.run }
    sleep 0.3

    thread.alive?.should eq(true)
    lines = logger_file.read.lines
    lines.select { |l| l.include?('my-plugin my-source: Data: {:foo=>12}') }.should have_at_least(2).items

    thread.exit
    agent.interrupt
    Bipbip.logger = nil
  end

  it 'should log plugin errors and retry' do
    logger_file = Tempfile.new('bipbip-mock-logger')
    Bipbip.logger = Logger.new(logger_file.path)

    plugin = Bipbip::Plugin.new('my-plugin', {}, 0.1)
    plugin.stub(:metrics_schema) { [] }
    plugin.stub(:source_identifier) { 'my-source' }
    plugin.stub(:monitor) { raise 'my-error' }

    agent.plugins = [plugin]

    thread = Thread.new { agent.run }
    sleep 0.3

    thread.alive?.should eq(true)
    lines = logger_file.read.lines
    lines.select { |l| l.include?('my-plugin my-source: my-error') }.should have_at_least(2).items
    lines.select { |l| l.include?('Plugin my-plugin with config {} terminated. Restarting...') }.should have_exactly(0).items

    thread.exit
    agent.interrupt
    Bipbip.logger = nil
  end

  it 'should log plugin exceptions and restart' do
    logger_file = Tempfile.new('bipbip-mock-logger')
    Bipbip.logger = Logger.new(logger_file.path)

    agent.stub(:interruptible_sleep) {}

    Bipbip::Plugin.any_instance.stub(:metrics_schema) { [] }
    Bipbip::Plugin.any_instance.stub(:source_identifier) { 'my-source' }
    Bipbip::Plugin.any_instance.stub(:monitor) { raise Exception.new('my-exception') }

    plugin = Bipbip::Plugin.new('my-plugin', {}, 0.1)
    agent.plugins = [plugin]

    thread = Thread.new { agent.run }
    sleep 0.3

    thread.alive?.should eq(true)
    lines = logger_file.read.lines
    lines.select { |l| l.include?('my-plugin my-source: my-exception') }.should have_at_least(2).items
    lines.select { |l| l.include?('Plugin my-plugin with config {} terminated. Restarting...') }.should have_at_least(2).items

    thread.exit
    agent.interrupt
    Bipbip.logger = nil
  end

end
