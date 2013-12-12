require 'bipbip'
require 'bipbip/plugin/memcached'

describe Bipbip::Agent do
  let(:agent) { Bipbip::Agent.new }
  let(:plugin) { Bipbip::Plugin::Memcached.new('memcached', {'hostname' => 'localhost', 'port' => 123}, 10) }

  it 'should run and warn' do
    Bipbip.logger = double('logger')

    Bipbip.logger.should_receive(:info).with('Startup...')
    Bipbip.logger.should_receive(:warn).with('No services configured')
    Bipbip.logger.should_receive(:warn).with('No storages configured')

    thread = Thread.new { agent.run }
    sleep 0.1

    thread.alive?.should eq(true)

    Bipbip.logger = nil
  end

  it 'should fork' do
    Bipbip.logger = Logger.new('/dev/null')
    agent.plugins = [plugin]

    plugin.should_receive(:run)

    thread = Thread.new { agent.run }
    sleep 0.1

    thread.alive?.should eq(true)

    Bipbip.logger = nil
  end
end
