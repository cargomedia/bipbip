require 'bipbip'

describe Bipbip::Agent do
  let(:agent) { Bipbip::Agent.new }

  it 'should exit without api key' do
    lambda {
      agent.run
    }.should raise_error SystemExit
  end

  it 'should run' do

    thread = Thread.new do
      agent.copperegg_api_key = 'foo'
      agent.run
    end

    lambda {
      agent.run
    }.should raise_error SystemExit
  end
end
