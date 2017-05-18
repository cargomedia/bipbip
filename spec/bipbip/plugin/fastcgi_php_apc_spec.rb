require 'bipbip'
require 'bipbip/plugin/fastcgi_php_apc'

describe Bipbip::Plugin::FastcgiPhpApc do
  let(:plugin) { Bipbip::Plugin::FastcgiPhpApc.new('php5-fpm-apc', { 'host' => 'localhost', 'port' => 9_999 }, 10) }

  it 'should collect data' do
    plugin.stub(:_fetch_apc_stats).and_return(
      'opcode_mem_size' => 100_000,
      'user_mem_size' => 50_000,
      'total_mem_size' => 2_000_000,
      'avail_mem_size' => 1_490_000,
      'used_mem_size' => 510_000
    )

    data = plugin.monitor
    data['opcode_mem_size'].should eq(100_000)
    data['user_mem_size'].should eq(50_000)
    data['avail_mem_size'].should eq(1_490_000)
    data['mem_used_percentage'].should eq(25.5)
  end
end
