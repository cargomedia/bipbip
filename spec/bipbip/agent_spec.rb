require 'bipbip'

describe Bipbip::Agent do
  let(:agent) { Bipbip::Agent.new }

  it 'should exit without api key' do
    lambda {
      agent.run
    }.should raise_error SystemExit
  end
end
