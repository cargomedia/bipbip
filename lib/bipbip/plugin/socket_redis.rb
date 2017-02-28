require 'net/http'

module Bipbip
  class Plugin::SocketRedis < Plugin
    def metrics_schema
      [
        { name: 'channels_count', type: 'gauge', unit: 'Channels' },
        { name: 'subscribers_count', type: 'gauge', unit: 'Subscribers' }
      ]
    end

    def monitor
      stats = fetch_socket_redis_status
      {
        'channels_count' => stats.length,
        'subscribers_count' => stats.values.reduce(0) { |memo, channel| memo += channel['subscribers'].length }
      }
    end

    private

    def fetch_socket_redis_status
      url = config['url'] || 'http://localhost:8085/status'
      uri = URI.parse(url)

      request = Net::HTTP::Get.new(uri)
      request['authorization'] = "token #{config['status_token']}" if config['status_token']

      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end

      unless response.code == '200'
        raise "Invalid response from server at `#{url}`. Response code `#{response.code}`, message `#{response.message}`, body `#{response.body}`"
      end

      JSON.parse(response.body)
    end
  end
end
