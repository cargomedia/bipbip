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
        { name: 'streams_zero_bitrate_count', type: 'gauge', unit: 'Streams' },
        { name: 'streams_packet_loss_audio_max', type: 'gauge', unit: '%' },
        { name: 'streams_packet_loss_audio_avg', type: 'gauge', unit: '%' },
        { name: 'streams_packet_loss_video_max', type: 'gauge', unit: '%' },
        { name: 'streams_packet_loss_video_avg', type: 'gauge', unit: '%' }
      ]
    end

    def monitor
      data = _fetch_data
      mountpoints = data['data']['list']
      streams = mountpoints.map { |mp| mp['streams'] }.flatten

      packet_loss_audio_avg = streams.count != 0 ? streams.map { |s| s['stats']['audio']['packet-loss'] || 0 }.reduce(0, :+) / streams.count : 0
      packet_loss_video_avg = streams.count != 0 ? streams.map { |s| s['stats']['video']['packet-loss'] || 0 }.reduce(0, :+) / streams.count : 0

      {
        'mountpoint_count' => mountpoints.count,
        'stream_count' => streams.count,
        'streams_listener_count' => streams.map { |s| s['webrtc-endpoint']['listeners'] }.reduce(0, :+),
        'streams_waiter_count' => streams.map { |s| s['webrtc-endpoint']['waiters'] }.reduce(0, :+),
        'streams_bandwidth' => streams.map { |s| (s['stats']['video']['bitrate'] || 0) + (s['stats']['audio']['bitrate'] || 0) }.reduce(0, :+),
        'streams_zero_fps_count' => streams.count { |s| s['frame']['fps'] == 0 },
        'streams_zero_bitrate_count' => streams.count { |s| s['stats']['video']['bitrate'].nil? || s['stats']['video']['bitrate'] == 0  },
        'streams_packet_loss_audio_max' => streams.map { |s| (s['stats']['audio']['packet-loss'] || 0) * 100 }.max,
        'streams_packet_loss_audio_avg' => packet_loss_audio_avg * 100,
        'streams_packet_loss_video_max' => streams.map { |s| (s['stats']['video']['packet-loss'] || 0) * 100 }.max,
        'streams_packet_loss_video_avg' => packet_loss_video_avg * 100
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
              promise.fail("Failed to get list of mountpoints: #{error}").execute
            end
          end.rescue do |error|
            promise.fail("Failed to create rtpbroadcast plugin: #{error}").execute
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
    # @param [String] session_data
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
      plugin = JanusGateway::Plugin::Rtpbroadcast.new(client, session)
      plugin.create
    end
  end
end
