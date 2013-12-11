module Bipbip

  class Plugin::PhpApc < Plugin

    def metrics_schema
      [
          {:name => 'opcode_mem_size', :type => 'ce_gauge', :unit => 'b'},
          {:name => 'user_mem_size', :type => 'ce_gauge', :unit => 'b'},
      ]
    end

    def monitor(server)
      uri = URI.parse(server['url'])
      response = Net::HTTP.get_response(uri)

      raise "Invalid response from server at #{server['url']}" unless response.code == '200'

      stats = JSON.parse(response.body)

      {:opcode_mem_size => stats['opcode_mem_size'].to_i, :user_mem_size => stats['user_mem_size'].to_i}
    end
  end
end
