require 'bipbip'
require 'bipbip/plugin/janus'

describe Bipbip::Plugin::Janus do
  let(:plugin) { Bipbip::Plugin::Janus.new('coturn', { 'url' => 'http://10.10.10.111:8088/janus' }, 10) }

  it 'should collect janus rtpbroadcast status data' do
    response = <<EOS
{
  "plugin": "janus.plugin.cm.rtpbroadcast",
  "data": {
    "streaming": "list",
    "list": [
      {
        "id": "1",
        "name": "1",
        "description": "Opus/VP8 tester.py test stream",
        "streams": [
          {
            "id": "1",
            "index": 1,
            "audioport": 8784,
            "videoport": 8504,
            "stats": {"min": 0.0, "max": 10.0, "cur": 5.0, "avg": 5.0},
            "frame": {"width": 0, "height": 0, "fps": 10, "key-distance": 0},
            "session": {"webrtc-active": 0, "autoswitch-enabled": 1, "remb-avg": 0}
          },
          {
            "id": "1",
            "index": 2,
            "audioport": 8018,
            "videoport": 8624,
            "stats": {"min": 0.0, "max": 20.0, "cur": 10.0, "avg": 10.0},
            "frame": {"width": 0, "height": 0, "fps": 30, "key-distance": 0},
            "session": {"webrtc-active": 0, "autoswitch-enabled": 1, "remb-avg": 0}
          },
          {
            "id": "1",
            "index": 3,
            "audioport": 8312,
            "videoport": 8267,
            "stats": {"min": 0.0, "max": 0.0, "cur": 0.0, "avg": 0.0},
            "frame": {"width": 0, "height": 0, "fps": 0, "key-distance": 0},
            "session": {"webrtc-active": 0, "autoswitch-enabled": 1, "remb-avg": 0
            }
          }
        ]
      }
    ]
  }
}
EOS

    plugin.stub(:_fetch_rtpbroadcast_data).and_return(JSON.parse(response))

    data = plugin.monitor

    data['rtpbroadcast_mountpoints_count'].should eq(1)
    data['rtpbroadcast_total_streams_count'].should eq(3)
    data['rtpbroadcast_total_streams_bandwidth'].should eq(15)
    data['rtpbroadcast_streams_zero_fps_count'].should eq(1)
    data['rtpbroadcast_streams_zero_bitrate_count'].should eq(1)
  end
end
