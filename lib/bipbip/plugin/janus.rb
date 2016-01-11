require 'janus_gateway'
require 'eventmachine'

module Bipbip
  class Plugin::Janus < Plugin
    def metrics_schema
      [
        { name: 'rtpbroadcast_mountpoints_count', type: 'gauge', unit: 'Mountpoints' },
        { name: 'rtpbroadcast_total_streams_count', type: 'gauge', unit: 'Streams' },
        { name: 'rtpbroadcast_total_streams_bandwidth', type: 'gauge', unit: 'b/s' },
        { name: 'rtpbroadcast_streams_zero_fps_count', type: 'gauge', unit: 'Streams' },
        { name: 'rtpbroadcast_streams_zero_bitrate_count', type: 'gauge', unit: 'Streams' }
      ]
    end

    def monitor
      data = _fetch_rtpbroadcast_data
      mountpoints = data['data']['list']
      {
        'rtpbroadcast_mountpoints_count' => mountpoints.count,
        'rtpbroadcast_total_streams_count' => mountpoints.map { |mp| mp['streams'].count }.reduce(:+),
        'rtpbroadcast_total_streams_bandwidth' => mountpoints.map { |mp| mp['streams'].map { |s| s['stats']['cur'] }.reduce(:+) }.reduce(:+),
        'rtpbroadcast_streams_zero_fps_count' => mountpoints.map { |mp| mp['streams'].select { |s| s['frame']['fps'] == 0 } }.count,
        'rtpbroadcast_streams_zero_bitrate_count' => mountpoints.map { |mp| mp['streams'].select { |s| s['stats']['cur'] == 0 } }.count
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
