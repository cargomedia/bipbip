require 'bipbip'
require 'bipbip/plugin/resque'

describe Bipbip::Plugin::Resque do
  let(:plugin) { Bipbip::Plugin::Resque.new('resque', { 'hostname' => 'redis', 'port' => 6379, 'namespace' => 'bipresquetest:', 'database' => 10 }, 10) }

  it 'should collect data' do
    # set up some mock workers - we just track whether they're idle or not
    allow(::Resque).to receive(:workers).and_return(
      [
        double(idle?: false),
        double(idle?: true),
        double(idle?: true),
        double(idle?: false),
        double(idle?: false)
      ]
    )

    # set up some mock queues
    mock_queues = {
      'special_stuff' => 3,
      'low_priority' => 10,
      'critical' => 0
    }

    allow(::Resque).to receive(:queues).and_return(mock_queues.keys)
    allow(::Resque).to receive(:size) do |queue|
      mock_queues[queue]
    end

    allow(::Resque::Failure).to receive(:count).and_return(234)

    data = plugin.monitor

    data['num_workers'].should be_kind_of(Integer)
    data['num_idle_workers'].should be_kind_of(Integer)
    data['num_active_workers'].should be_kind_of(Integer)
    data['num_workers'].should eq(5)
    data['num_idle_workers'].should eq(2)
    data['num_active_workers'].should eq(3)
    data['num_failures'].should eq(234)
    data['queue_size_special_stuff'].should eq(3)
    data['queue_size_low_priority'].should eq(10)
    data['queue_size_critical'].should eq(0)
  end
end
