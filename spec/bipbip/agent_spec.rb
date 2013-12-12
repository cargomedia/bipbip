require 'bipbip'

describe Bipbip::Agent do
  let(:agent) { Bipbip::Agent.new }

  it 'should run and warn' do
    Bipbip.logger = double('logger')

    Bipbip.logger.should_receive(:info).with('Startup...')
    Bipbip.logger.should_receive(:warn).with('No services configured')
    Bipbip.logger.should_receive(:warn).with('No storages configured')

    thread = Thread.new { agent.run }
    sleep 0.1

    thread.alive?.should == true
  end
end
