require 'bipbip'
require 'bipbip/plugin/janus_audioroom'

describe Bipbip::Plugin::JanusAudioroom do
  let(:plugin) { Bipbip::Plugin::JanusAudioroom.new('coturn', { 'url' => 'http://10.10.10.111:8088/janus' }, 10) }

  it 'should collect janus audioroom status data' do
    response = <<EOS
{
  "plugin": "janus.plugin.cm.audioroom",
  "data": {
    "audioroom": "success",
    "list": [
      {
        "sampling_rate": 16000,
        "record": "true",
        "id": "super-magic-room",
        "num_participants": 3,
        "description": "Room super-magic-room"
      },
      {
        "sampling_rate": 48000,
        "record": "true",
        "id": "super-magic-room",
        "num_participants": 7,
        "description": "Room super-fooboo-room"
      }
    ]
  }
}
EOS

    plugin.stub(:_fetch_audioroom_data).and_return(JSON.parse(response))

    data = plugin.monitor

    data['audioroom_room_count'].should eq(2)
  end
end
