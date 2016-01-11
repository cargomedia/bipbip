require 'janus_gateway'
require 'eventmachine'

module Bipbip
  class Plugin::Janus < Plugin
    def metrics_schema
      [
        { name: 'rtpbroadcast_mountpoints_count', type: 'gauge', unit: 'Mountpoints' }
      ]
    end

    def monitor
      data = _fetch_rtpbroadcast_data
      mountpoints = data['data']['list']
      {
        'rtpbroadcast_mountpoints_count' => mountpoints.count
      }
    end

    private

    def _fetch_rtpbroadcast_data
      promise = Concurrent::Promise.new

      client = _create_client('http://10.10.10.111:8088/janus')
      client.connect

      _create_session(client).then do |session|
        _create_plugin(client, session).then do |plugin|
          _request_list(client, plugin).then do |list|
            data = list.data
            promise.set(data).execute
          end.rescue do |error|
            fail "Failed to get list: #{error}"
          end
        end.rescue do |error|
          fail "Failed to create plugin: #{error}"
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
      plugin = JanusGateway::Plugin::Rtpbroadcast.new(client, session)
      plugin.on(:destroy) do
        fail 'Plugin got destroyed.'
      end
      plugin.create
    end

    # @param [JanusGateway::Client] client
    # @param [JanusGateway::Plugin::Rtpbroadcast] plugin
    def _request_list(client, plugin)
      list = JanusGateway::Plugin::Rtpbroadcast::List.new(client, plugin)
      list.create
    end
  end
end
