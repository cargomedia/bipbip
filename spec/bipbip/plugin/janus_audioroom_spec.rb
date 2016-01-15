require 'bipbip'
require 'bipbip/plugin/janus_audioroom'

describe Bipbip::Plugin::JanusAudioroom do
  let(:plugin) { Bipbip::Plugin::JanusAudioroom.new('coturn', { 'url' => 'http://localhost:8088/janus' }, 10) }

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
        "id": "super-fooboo-room",
        "num_participants": 7,
        "description": "Room super-fooboo-room"
      },
      {
        "sampling_rate": 16000,
        "record": "true",
        "id": "super-foo-boo",
        "num_participants": 0,
        "description": "Room super-foo-boo"
      }
    ]
  }
}
EOS

    plugin.stub(:_fetch_audioroom_data).and_return(JSON.parse(response))

    data = plugin.monitor

    data['audioroom_rooms_count'].should eq(3)
    data['audioroom_participants_count'].should eq(10)
    data['audioroom_room_zero_participant_count'].should eq(1)
  end
end
