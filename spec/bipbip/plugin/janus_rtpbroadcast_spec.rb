require 'bipbip'
require 'bipbip/plugin/janus_rtpbroadcast'

describe Bipbip::Plugin::JanusRtpbroadcast do
  let(:plugin) { Bipbip::Plugin::JanusRtpbroadcast.new('janus-rtpbroadcast', { 'url' => 'http://localhost:8088/janus' }, 10) }

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
            "listeners": 32,
            "waiters": 4,
            "stats": {"min": 0.0, "max": 10.0, "cur": 5.0, "avg": 5.0},
            "frame": {"width": 0, "height": 0, "fps": 10, "key-distance": 20},
            "session": {"webrtc-active": 0, "autoswitch-enabled": 1, "remb-avg": 0}
          },
          {
            "id": "1",
            "index": 2,
            "audioport": 8018,
            "videoport": 8624,
            "listeners": 0,
            "waiters": 12,
            "stats": {"min": 0.0, "max": 20.0, "cur": 10.0, "avg": 10.0},
            "frame": {"width": 0, "height": 0, "fps": 30, "key-distance": 30},
            "session": {"webrtc-active": 0, "autoswitch-enabled": 1, "remb-avg": 0}
          },
          {
            "id": "1",
            "index": 3,
            "audioport": 8312,
            "videoport": 8267,
            "listeners": 88,
            "waiters": 12,
            "stats": {"min": 0.0, "max": 0.0, "cur": 0.0, "avg": 0.0},
            "frame": {"width": 0, "height": 0, "fps": 0, "key-distance": 40},
            "session": {"webrtc-active": 0, "autoswitch-enabled": 1, "remb-avg": 0
            }
          }
        ]
      },
      {
        "id": "2",
        "name": "2",
        "description": "Opus/VP8 tester.py test stream",
        "streams": [
          {
            "id": "2",
            "index": 1,
            "audioport": 9784,
            "videoport": 9504,
            "listeners": 200,
            "waiters": 100,
            "stats": {"min": 0.0, "max": 100.0, "cur": 50.0, "avg": 50.0},
            "frame": {"width": 0, "height": 0, "fps": 50, "key-distance": 50},
            "session": {"webrtc-active": 0, "autoswitch-enabled": 1, "remb-avg": 0}
          }
        ]
      }
    ]
  }
}
EOS

    plugin.stub(:_fetch_data).and_return(JSON.parse(response))

    data = plugin.monitor

    data['mountpoint_count'].should eq(2)
    data['stream_count'].should eq(4)
    data['streams_listener_count'].should eq(320)
    data['streams_waiter_count'].should eq(128)
    data['streams_bandwidth'].should eq(65)
    data['streams_zero_fps_count'].should eq(1)
    data['streams_zero_bitrate_count'].should eq(1)
  end

  it 'should handle empty list of mountpoints' do
    response = <<EOS
{
  "plugin": "janus.plugin.cm.rtpbroadcast",
  "data": {
    "streaming": "list",
    "list": []
  }
}
EOS

    plugin.stub(:_fetch_data).and_return(JSON.parse(response))

    data = plugin.monitor

    data['mountpoint_count'].should eq(0)
    data['stream_count'].should eq(0)
    data['streams_listener_count'].should eq(0)
    data['streams_waiter_count'].should eq(0)
    data['streams_bandwidth'].should eq(0)
    data['streams_zero_fps_count'].should eq(0)
    data['streams_zero_bitrate_count'].should eq(0)
  end
end
