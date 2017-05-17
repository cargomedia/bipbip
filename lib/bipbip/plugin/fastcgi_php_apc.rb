module Bipbip
  class Plugin::FastcgiPhpApc < Plugin
    def metrics_schema
      [
        { name: 'opcode_mem_size', type: 'gauge', unit: 'b' },
        { name: 'user_mem_size', type: 'gauge', unit: 'b' },
        { name: 'avail_mem_size', type: 'gauge', unit: 'b' },
        { name: 'mem_used_percentage', type: 'gauge', unit: '%' }
      ]
    end

    # @return [Integer]
    def _total_system_memory
      `free -b`.lines.to_a[1].split[1].to_i
    end

    # @return [Hash]
    def _fetch_apc_data
      authority = config['host'].to_s + ':' + config['port'].to_s
      path = File.join(Bipbip::Helper.data_path, 'apc-status.php')

      env_backup = ENV.to_hash
      ENV['REQUEST_METHOD'] = 'GET'
      ENV['SCRIPT_NAME'] = File.basename(path)
      ENV['SCRIPT_FILENAME'] = path
      response = `cgi-fcgi -bind -connect #{authority.shellescape} 2>&1`
      ENV.replace(env_backup)

      body = response.split(/\r?\n\r?\n/)[1]
      raise "FastCGI response has no body: #{response}" unless body
      JSON.parse(body)
    end

    def monitor
      stats = _fetch_apc_data
      data = {}
      data['opcode_mem_size'] = stats['opcode_mem_size'].to_i
      data['user_mem_size'] = stats['user_mem_size'].to_i
      data['avail_mem_size'] = stats['avail_mem_size'].to_i
      data['mem_used_percentage'] = ((_total_system_memory.to_f - data['avail_mem_size'].to_f) / _total_system_memory.to_f) * 100
      data
    end
  end
end
