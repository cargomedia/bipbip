module Bipbip
  class Plugin::PhpApc < Plugin
    def metrics_schema
      [
        { name: 'opcode_mem_size', type: 'gauge', unit: 'b' },
        { name: 'user_mem_size', type: 'gauge', unit: 'b' }
      ]
    end

    def monitor
      uri = URI.parse(config['url'])
      response = Net::HTTP.get_response(uri)

      raise "Invalid response from server at #{config['url']}" unless response.code == '200'

      stats = JSON.parse(response.body)

      { opcode_mem_size: stats['opcode_mem_size'].to_i, user_mem_size: stats['user_mem_size'].to_i }
    end
  end
end
