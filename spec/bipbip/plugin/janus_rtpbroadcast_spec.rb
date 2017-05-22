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
        "uid": "4da7fe6edf6828474300c5d5f7074284",
        "name": "1",
        "description": "Opus/VP8 tester.py test stream",
        "streams": [
          {
            "id": "1",
            "uid": "4da7fe6edf6828474300c5d5f7074284",
            "index": 1,
            "rtp-endpoint": {
                "audio": {"host": "127.0.0.1","port": 8139},
                "video": {"host": "127.0.0.1", "port": 8888}
            },
            "webrtc-endpoint": {"listeners": 32, "waiters": 4},
            "stats": {
                "audio": {"packet-loss-rate": 0.1, "packet-loss-count": 100, "bitrate": 1},
                "video": {"packet-loss-rate": 0.4, "packet-loss-count": 100, "bitrate": 4}
            },
            "frame": {"width": 0, "height": 0, "fps": 10, "key-distance": 20},
            "session": {"webrtc-active": 0, "autoswitch-enabled": 1, "remb-avg": 0}
          },
          {
            "id": "1",
            "uid": "4da7fe6edf6828474300c5d5f7074284",
            "index": 2,
            "rtp-endpoint": {
                "audio": {"host": "127.0.0.1","port": 8018},
                "video": {"host": "127.0.0.1", "port": 8624}
            },
            "webrtc-endpoint": {"listeners": 0, "waiters": 12},
            "stats": {
                "audio": {"packet-loss-rate": 0.9, "packet-loss-count": 10, "bitrate": 3},
                "video": {"packet-loss-rate": 0.1, "packet-loss-count": 100, "bitrate": 7}
            },
            "frame": {"width": 0, "height": 0, "fps": 30, "key-distance": 30},
            "session": {"webrtc-active": 0, "autoswitch-enabled": 1, "remb-avg": 0}
          },
          {
            "id": "1",
            "uid": "4da7fe6edf6828474300c5d5f7074284",
            "index": 3,
            "rtp-endpoint": {
                "audio": {"host": "127.0.0.1","port": 8312},
                "video": {"host": "127.0.0.1", "port": 8267}
            },
            "webrtc-endpoint": {"listeners": 88, "waiters": 12},
            "stats": {
                "audio": {"packet-loss-rate": 0.9, "packet-loss-count": 1000, "bitrate": 0},
                "video": {"packet-loss-rate": 0.1, "packet-loss-count": 1000, "bitrate": 0}
            },
            "frame": {"width": 0, "height": 0, "fps": 0, "key-distance": 40},
            "session": {"webrtc-active": 0, "autoswitch-enabled": 1, "remb-avg": 0
            }
          }
        ]
      },
      {
        "id": "2",
        "uid": "ABCDEF6edf6828474300c5d5f7074284",
        "name": "2",
        "description": "Opus/VP8 tester.py test stream",
        "streams": [
          {
            "id": "2",
            "uid": "ABCDEF6edf6828474300c5d5f7074284",
            "index": 1,
            "rtp-endpoint": {
                "audio": {"host": "127.0.0.1","port": 9784},
                "video": {"host": "127.0.0.1", "port": 9504}
            },
            "webrtc-endpoint": {"listeners": 200, "waiters": 100},
            "stats": {
                "audio": {"packet-loss-rate": 0.5, "packet-loss-count": 1, "bitrate": 10},
                "video": {"packet-loss-rate": 0.2, "packet-loss-count": 1, "bitrate": 40}
            },
            "frame": {"width": 0, "height": 0, "fps": 50, "key-distance": 50},
            "session": {"webrtc-active": 0, "autoswitch-enabled": 1, "remb-avg": 0}
          }
        ]
      }
    ]
  }
}
EOS

    allow(plugin).to receive(:_fetch_data).and_return(JSON.parse(response))

    data = plugin.monitor

    data['mountpoint_count'].should eq(2)
    data['stream_count'].should eq(4)
    data['streams_listener_count'].should eq(320)
    data['streams_waiter_count'].should eq(128)
    data['streams_bandwidth'].should eq(65)
    data['streams_zero_fps_count'].should eq(1)
    data['streams_zero_bitrate_count'].should eq(1)
    data['streams_packet_loss_audio_max'].should eq(90)
    data['streams_packet_loss_audio_avg'].should eq(60)
    data['streams_packet_loss_audio_count'].should eq(1111)
    data['streams_packet_loss_video_max'].should eq(40)
    data['streams_packet_loss_video_count'].should eq(1201)
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

    allow(plugin).to receive(:_fetch_data).and_return(JSON.parse(response))

    data = plugin.monitor

    data['mountpoint_count'].should eq(0)
    data['stream_count'].should eq(0)
    data['streams_listener_count'].should eq(0)
    data['streams_waiter_count'].should eq(0)
    data['streams_bandwidth'].should eq(0)
    data['streams_zero_fps_count'].should eq(0)
    data['streams_zero_bitrate_count'].should eq(0)
  end

  it 'should handle null values in responses' do
    response = <<EOS
{
  "plugin": "janus.plugin.cm.rtpbroadcast",
  "data": {
    "streaming": "list",
    "list": [
      {
        "id": "0",
        "uid": "XXXXXX6edf6828474300c5d5f7074284",
        "name": "0",
        "description": "Opus/VP8 tester.py test stream",
        "streams": [
          {
            "id": "2",
            "uid": "XXXXXX6edf6828474300c5d5f7074284",
            "index": 1,
            "rtp-endpoint": {
                "audio": {"host": "127.0.0.1","port": 9784},
                "video": {"host": "127.0.0.1", "port": 9504}
            },
            "webrtc-endpoint": {"listeners": 200, "waiters": 100},
            "stats": {
                "audio": {"packet-loss-rate": null, "packet-loss-count": null, "bitrate": null},
                "video": {"packet-loss-rate": null, "packet-loss-count": null, "bitrate": null}
            },
            "frame": {"width": 0, "height": 0, "fps": 50, "key-distance": 50},
            "session": {"webrtc-active": 0, "autoswitch-enabled": 1, "remb-avg": null }
          }
        ]
      }
    ]
  }
}
EOS

    allow(plugin).to receive(:_fetch_data).and_return(JSON.parse(response))

    data = plugin.monitor

    data['mountpoint_count'].should eq(1)
    data['stream_count'].should eq(1)
    data['streams_listener_count'].should eq(200)
    data['streams_waiter_count'].should eq(100)
    data['streams_bandwidth'].should eq(0)
    data['streams_zero_bitrate_count'].should eq(1)
    data['streams_packet_loss_audio_max'].should eq(0)
    data['streams_packet_loss_audio_avg'].should eq(0)
    data['streams_packet_loss_audio_count'].should eq(0)
    data['streams_packet_loss_video_max'].should eq(0)
    data['streams_packet_loss_video_avg'].should eq(0)
    data['streams_packet_loss_video_count'].should eq(0)
  end
end
