require 'janus_gateway'

module Bipbip
  class Plugin::JanusAudioroom < Plugin
    def metrics_schema
      [
        { name: 'audioroom_rooms_count', type: 'gauge', unit: 'Rooms' },
        { name: 'audioroom_participants_count', type: 'gauge', unit: 'Participants' },
        { name: 'audioroom_room_zero_participant_count', type: 'gauge', unit: 'Rooms' }
      ]
    end

    def monitor
      data_audio = _fetch_audioroom_data
      audiorooms = data_audio['data']['list']
      {
        'audioroom_rooms_count' => audiorooms.count,
        'audioroom_participants_count' => audiorooms.map { |room| room['num_participants'] }.reduce(:+),
        'audioroom_room_zero_participant_count' => audiorooms.select { |room| room['num_participants'] == 0 }.count
      }
    end

    private

    def _fetch_audioroom_data
      promise = Concurrent::Promise.new

      client = _create_client(config['url'] || 'http://localhost:8088/janus')

      _create_session(client).then do |session|
        _create_plugin(client, session).then do |plugin|
          plugin.list.then do |list|
            data = list['plugindata']
            promise.set(data).execute

            session.destroy
          end.rescue do |error|
            fail "Failed to get list of audioroom: #{error}"
          end
        end.rescue do |error|
          fail "Failed to create audioroom plugin: #{error}"
        end
      end.rescue do |error|
        fail "Failed to create session: #{error}"
      end

      promise.value
    end

    # @param [String] http_url
    # @return [JanusGateway::Client]
    def _create_client(http_url)
      transport = JanusGateway::Transport::Http.new(http_url)
      client = JanusGateway::Client.new(transport)

      client.on(:close) do
        fail 'Connection to Janus closed.'
      end
      client
    end

    # @param [JanusGateway::Client] client
    # @return [Concurrent::Promise]
    def _create_session(client)
      session = JanusGateway::Resource::Session.new(client)
      session.on(:destroy) do
        fail 'Session got destroyed.'
      end
      session.create
    end

    # @param [JanusGateway::Client] client
    # @param [JanusGateway::Resource::Session] session
    # @return [Concurrent::Promise]
    def _create_plugin(client, session)
      plugin = JanusGateway::Plugin::Audioroom.new(client, session)
      plugin.on(:destroy) do
        fail 'Plugin got destroyed.'
      end
      plugin.create
    end
  end
end
