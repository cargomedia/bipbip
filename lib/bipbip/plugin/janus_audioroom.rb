require 'janus_gateway'
require 'eventmachine'

module Bipbip
  class Plugin::JanusAudioroom < Plugin
    def metrics_schema
      [
        { name: 'room_count', type: 'gauge', unit: 'Rooms' },
        { name: 'participant_count', type: 'gauge', unit: 'Participants' },
        { name: 'room_zero_participant_count', type: 'gauge', unit: 'Rooms' }
      ]
    end

    def monitor
      data = _fetch_data
      audiorooms = data['data']['list']
      {
        'room_count' => audiorooms.count,
        'participant_count' => audiorooms.map { |room| room['num_participants'] }.reduce(0, :+),
        'room_zero_participant_count' => audiorooms.count { |room| room['num_participants'] == 0 }
      }
    end

    private

    def _fetch_data
      promise = Concurrent::Promise.new

      EM.run do
        EM.error_handler do |error|
          promise.fail(error).execute
        end

        client = _create_client(config['url'] || 'http://127.0.0.1:8088/janus')

        _create_session(client).then do |session|
          _create_plugin(client, session).then do |plugin|
            plugin.list.then do |list|
              data = list['plugindata']

              session.destroy.value
              promise.set(data).execute
            end.rescue do |error|
              promise.fail("Failed to get list of audioroom: #{error}").execute
            end
          end.rescue do |error|
            promise.fail("Failed to create audioroom plugin: #{error}").execute
          end
        end.rescue do |error|
          promise.fail("Failed to create session: #{error}").execute
        end

        promise.then { EM.stop }
        promise.rescue { EM.stop }
      end

      promise.rescue do |error|
        raise(error)
      end

      promise.value
    end

    # @param [String] http_url
    # @return [JanusGateway::Client]
    def _create_client(http_url)
      transport = JanusGateway::Transport::Http.new(http_url)
      client = JanusGateway::Client.new(transport)
      client
    end

    # @param [JanusGateway::Client] client
    # @return [Concurrent::Promise]
    def _create_session(client)
      session = JanusGateway::Resource::Session.new(client)
      session.create
    end

    # @param [JanusGateway::Client] client
    # @param [JanusGateway::Resource::Session] session
    # @return [Concurrent::Promise]
    def _create_plugin(client, session)
      plugin = JanusGateway::Plugin::Audioroom.new(client, session)
      plugin.create
    end
  end
end
