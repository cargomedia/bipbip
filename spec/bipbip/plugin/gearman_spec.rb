require 'bipbip'
require 'bipbip/plugin/gearman'

describe Bipbip::Plugin::Gearman do
  let(:plugin) { Bipbip::Plugin::Gearman.new('mysql', { 'hostname' => 'localhost', 'port' => 4730, 'persistence' => 'mysql' }, 10) }

  it 'should collect data' do
    plugin.stub(:_fetch_gearman_status).and_return(
      function1: { queue: 5, active: 1 },
      function2: { queue: 10, active: 2 },
      function3: { queue: 15, active: 3 }
    )

    plugin.stub(:_fetch_mysql_priority_stats).and_return(
      Bipbip::Plugin::Gearman::PRIORITY_LOW => 5,
      Bipbip::Plugin::Gearman::PRIORITY_NORMAL => 10,
      Bipbip::Plugin::Gearman::PRIORITY_HIGH => 15
    )

    data = plugin.monitor

    data[:jobs_queued_total].should eq(30)
    data[:jobs_active_total].should eq(6)
    data[:jobs_waiting_total].should eq(24)
    data[:jobs_queued_total_low].should eq(5)
    data[:jobs_queued_total_normal].should eq(10)
    data[:jobs_queued_total_high].should eq(15)
  end
end
