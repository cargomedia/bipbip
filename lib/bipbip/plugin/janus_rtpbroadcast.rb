require 'janus_gateway'

module Bipbip
  class Plugin::JanusRtpbroadcast < Plugin
    def metrics_schema
      [
        { name: 'mountpoint_count', type: 'gauge', unit: 'Mountpoints' },
        { name: 'stream_count', type: 'gauge', unit: 'Streams' },
        { name: 'streams_listener_count', type: 'gauge', unit: 'Listeners' },
        { name: 'streams_waiter_count', type: 'gauge', unit: 'Waiters' },
        { name: 'streams_bandwidth', type: 'gauge', unit: 'b/s' },
        { name: 'streams_zero_fps_count', type: 'gauge', unit: 'Streams' },
        { name: 'streams_zero_bitrate_count', type: 'gauge', unit: 'Streams' }
      ]
    end

    def monitor
      data = _fetch_data
      mountpoints = data.nil? ? [] : data['data']['list']
      streams = mountpoints.map { |mp| mp['streams'] }.flatten
      {
        'mountpoint_count' => mountpoints.count,
        'stream_count' => streams.count,
        'streams_listener_count' => streams.map { |s| s['listeners'] || 0 }.reduce(:+),
        'streams_waiter_count' => streams.map { |s| s['waiters'] || 0 }.reduce(:+),
        'streams_bandwidth' => streams.map { |s| s['stats']['cur'] }.reduce(:+),
        'streams_zero_fps_count' => streams.count { |s| s['frame']['fps'] == 0 },
        'streams_zero_bitrate_count' => streams.count { |s| s['stats']['cur'] == 0 }
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

              EM.stop
            end.rescue do |error|
              promise.fail("Failed to get list of mountpoints: #{error}").execute
            end
          end.rescue do |error|
            promise.fail("Failed to create rtpbroadcast plugin: #{error}").execute
          end
        end.rescue do |error|
          promise.fail("Failed to create session: #{error}").execute
        end

        promise.rescue do |_err|
          EM.stop
        end
      end

      promise.value
    end

    # @param [String] http_url
    # @param [String] session_data
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
      plugin = JanusGateway::Plugin::Rtpbroadcast.new(client, session)
      plugin.on(:destroy) do
        fail 'Plugin got destroyed.'
      end
      plugin.create
    end
  end
end
