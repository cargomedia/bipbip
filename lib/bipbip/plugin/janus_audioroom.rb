require 'janus_gateway'
require 'eventmachine'

module Bipbip
  class Plugin::JanusAudioroom < Plugin
    def metrics_schema
      [
        { name: 'audioroom_room_count', type: 'gauge', unit: 'Rooms' }
      ]
    end

    def monitor
      data_audio = _fetch_audioroom_data
      audiorooms = data_audio['data']['list']
      {
        'audioroom_room_count' => audiorooms.count,
      }
    end

    private

    def _fetch_audioroom_data
      promise = Concurrent::Promise.new

      client = _create_client(config['url'] || 'http://localhost:8088/janus')

      _create_session(client).then do |session|
        _create_plugin(client, session).then do |plugin|
          _request_list(client, plugin).then do |list|
            data = list.data
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

    # @param [String] websocket_url
    # @param [String] session_data
    # @return [JanusGateway::Client]
    def _create_client(websocket_url)
      transport = JanusGateway::Transport::Http.new(websocket_url)
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

    # @param [JanusGateway::Client] client
    # @param [JanusGateway::Plugin::Audioroom] plugin
    # @return [Concurrent::Promise]
    def _request_list(client, plugin)
      list = JanusGateway::Plugin::Audioroom::List.new(client, plugin)
      list.get
    end
  end
end
