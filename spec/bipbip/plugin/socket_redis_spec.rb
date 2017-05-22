require 'bipbip'
require 'bipbip/plugin/socket_redis'

describe Bipbip::Plugin::SocketRedis do
  let(:plugin) { Bipbip::Plugin::SocketRedis.new('socket-redis', {}, 10) }

  it 'should collect data' do
    allow(plugin).to receive(:fetch_socket_redis_status).and_return(
      'channel1' => {
        'subscribers' => {
          'sub1' => {},
          'sub2' => {}
        }
      },
      'channel2' => {
        'subscribers' => {
          'sub1' => {},
          'sub2' => {},
          'sub3' => {},
          'sub4' => {}
        }
      }
    )

    data = plugin.monitor

    data['channels_count'].should eq(2)
    data['subscribers_count'].should eq(6)
  end

  it 'should collect data for empty server response' do
    allow(plugin).to receive(:fetch_socket_redis_status).and_return({})

    data = plugin.monitor

    data['channels_count'].should eq(0)
    data['subscribers_count'].should eq(0)
  end
end
