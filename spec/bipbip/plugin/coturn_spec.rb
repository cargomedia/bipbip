require 'bipbip'
require 'bipbip/plugin/coturn'

describe Bipbip::Plugin::Coturn do
  let(:plugin) { Bipbip::Plugin::Coturn.new('coturn', { 'hostname' => 'localhost', 'port' => '5766' }, 10) }

  it 'should collect data for no sessions' do
    response = <<EOS

    Total sessions: 0
EOS

    plugin.stub(:_fetch_session_data).and_return(response)

    data = plugin.monitor

    data['total_sessions_count'].should eq(0)
    data['total_bitrate_outgoing'].should eq(0)
    data['total_bitrate_incoming'].should eq(0)
  end

  it 'should collect turnserver multiple sessions data' do
    response = <<EOS
    1) id=128000000000000076, user <njam>:
      realm: njam.com
    started 761 secs ago
    expiring in 16 secs
    client protocol UDP, relay protocol UDP
    client addr 127.0.0.1:43176, server addr 127.0.0.1:3478
    relay addr 127.0.0.1:61038
    fingerprints enforced: ON
    mobile: ON
    usage: rp=3, rb=308, sp=3, sb=364
    rate: r=101, s=1, total=0 (bytes per sec)

    2) id=128000000000000076, user <njam>:
      realm: njam.com
    started 761 secs ago
    expiring in 16 secs
    client protocol UDP, relay protocol UDP
    client addr 127.0.0.1:43176, server addr 127.0.0.1:3478
    relay addr 127.0.0.1:61038
    fingerprints enforced: ON
    mobile: ON
    usage: rp=3, rb=308, sp=3, sb=364
    rate: r=98, s=98, total=0 (bytes per sec)

    3) id=128000000000000076, user <njam>:
      realm: njam.com
    started 761 secs ago
    expiring in 16 secs
    client protocol UDP, relay protocol UDP
    client addr 127.0.0.1:43176, server addr 127.0.0.1:3478
    relay addr 127.0.0.1:61038
    fingerprints enforced: ON
    mobile: ON
    usage: rp=3, rb=308, sp=3, sb=364
    rate: r=1, s=901, total=0 (bytes per sec)

    Total sessions: 3
EOS

    plugin.stub(:_fetch_session_data).and_return(response)

    data = plugin.monitor

    data['total_sessions_count'].should eq(3)
    data['total_bitrate_outgoing'].should eq(1000 * 8)
    data['total_bitrate_incoming'].should eq(200 * 8)
  end

  it 'should raise error for malformed response' do
    response = <<EOS
    TURN Server
    Coturn-4.5.0.3 'dan Eider'

    Type '?' for help
    >
EOS

    plugin.stub(:_fetch_session_data).and_return(response)

    expect { plugin.monitor }.to raise_error(/Cannot prepare metrics for malformed response:/)
  end
end
