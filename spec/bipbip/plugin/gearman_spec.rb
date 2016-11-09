require 'bipbip'
require 'bipbip/plugin/gearman'

describe Bipbip::Plugin::Gearman do
  let(:plugin) { Bipbip::Plugin::Gearman.new('mysql', {'hostname' => 'localhost', 'port' => 4730, 'persistence' => 'mysql'}, 10) }

  it 'should collect data' do
    plugin.stub(:_fetch_gearman_status).and_return(
        {
            function1: {queue: 10, active: 2},
            function2: {queue: 5, active: 2},
        }
    )

    plugin.stub(:_fetch_mysql_priority_stats).and_return(
      {
          0 => 5,
          1 => 5,
          2 => 5
      }
    )

    data = plugin.monitor

    data[:jobs_queued_total].should eq(15)
    data[:jobs_active_total].should eq(4)
    data[:jobs_waiting_total].should eq(11)
    data[:jobs_low_priority_total].should eq(5)
    data[:jobs_normal_priority_total].should eq(5)
    data[:jobs_high_priority_total].should eq(5)
  end
end
