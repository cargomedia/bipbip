require 'bipbip'
require 'bipbip/plugin/memcached'
require 'tempfile'

describe Bipbip::Agent do
  let(:agent) { Bipbip::Agent.new }
  let(:plugin) { Bipbip::Plugin::Memcached.new('memcached', {'hostname' => 'localhost', 'port' => 123}, 10) }

  it 'should run and warn' do
    Bipbip.logger = double('logger')

    Bipbip.logger.should_receive(:info).with('Startup...')
    Bipbip.logger.should_receive(:warn).with('No services configured')
    Bipbip.logger.should_receive(:warn).with('No storages configured')

    thread = Thread.new { agent.run }
    sleep 0.5

    thread.alive?.should eq(true)

    Bipbip.logger = nil
  end

  it 'should fork' do
    Bipbip.logger = Logger.new('/dev/null')
    agent.plugins = [plugin]

    plugin.should_receive(:run)

    thread = Thread.new { agent.run }
    sleep 0.5

    thread.alive?.should eq(true)

    Bipbip.logger = nil
  end

  it 'should expect plugin errors' do
    logger_file = Tempfile.new('bipbip-mock-logger')
    Bipbip.logger = Logger.new(logger_file.path)

    plugin = Bipbip::Plugin.new('my-plugin', {}, 0.1)
    plugin.stub(:metrics_schema) { [] }
    plugin.stub(:source_identifier) { 'my-source' }
    plugin.stub(:monitor) { raise 'my error' }

    agent.plugins = [plugin]

    thread = Thread.new { agent.run }
    sleep 0.5

    thread.alive?.should eq(true)
    lines = logger_file.read.lines
    lines.select { |l| l.include?('my-plugin my-source: Error getting data: my error') }.should have_at_least(2).items

    Bipbip.logger = nil
  end
end
