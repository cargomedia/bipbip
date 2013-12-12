require 'bipbip'

describe Bipbip::Agent do
  let(:agent) { Bipbip::Agent.new }

  it 'should run' do
    Bipbip.logger = double('logger')

    Bipbip.logger.should_receive(:info).with('Startup...')
    Bipbip.logger.should_receive(:warn).with('No services configured')
    Bipbip.logger.should_receive(:warn).with('No storages configured')

    Thread.new do
      agent.run
    end
    sleep 0.1
  end
end
