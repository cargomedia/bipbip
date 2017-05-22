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

    # @return [Hash]
    def _fetch_apc_stats
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
      stats = _fetch_apc_stats
      {
        opcode_mem_size: stats['opcode_mem_size'].to_i,
        user_mem_size: stats['user_mem_size'].to_i,
        used_mem_size: stats['used_mem_size'].to_i,
        mem_used_percentage: (stats['used_mem_size'].to_f / stats['total_mem_size'].to_f) * 100
      }
    end
  end
end
