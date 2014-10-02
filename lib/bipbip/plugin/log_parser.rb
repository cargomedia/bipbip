require 'uri'

module Bipbip

  class Plugin::LogParser < Plugin

    def metrics_schema
      metric_list = [
          {:name => 'All_Logs_ok', :type => 'gauge', :unit => 'Boolean'}
      ]

      config['sources'].each do |name, config|
        metric_list.push({:name => name, :type => 'gauge', :unit => 'Boolean'})
      end

      metric_list
    end

    def monitor
      sources = config['sources']

      data = Hash.new(0)
      data['All_Logs_ok'] = 1

      sources.each do |name, config|
        data[name] = source_check(config) ? 1 : 0
        data['All_Logs_ok'] = 0 if data[name] == 0 && data['All_Logs_ok'] == 1
      end

      data
    end

    private

    def source_check(config)
      output = true

      _get_lines(config, 1).each do |line|
        output &= (line.match(Regexp.new(config['regexp_text']))).nil?
      end

      output
    end

    def source_uri(config)
      _uri(config['uri'])
    end

    def source_type(config)
      source_uri(config).scheme
    end

    def source_options(config)
      type = source_type(config)

      options = config['file_options'] if type == 'file'
      options = config['http_options'] if type == 'http'

      options
    end

    def source_path(config)
      uri = source_uri(config)
      type = source_type(config)

      path = uri.path if type == 'file'
      path = uri.to_s if type == 'http'

      path
    end

    def _get_lines(config, lines = 1)
      type = source_type(config)
      path = source_path(config)
      options = source_options(config)

      line_list = _file_get_lines(path, lines, options) if type == 'file'
      line_list = _http_get_lines(path, lines, options) if type == 'http'

      line_list
    end

    def _uri(uri)
      uri = URI(uri)
      raise 'URI is not uniform or valid' unless ['file', 'http'].include? uri.scheme

      uri
    end

    def _file_get_lines(path, lines, options)
      return [] if lines < 1

      raise 'File does not exist' unless File.exists?(path)

      if options.key?('regexp_timestamp') and options.key?('age_max')
        regexp_timestamp = Regexp.new(options['regexp_timestamp'])
        age_max = options['age_max'].to_i

        ending_at = Time.now
        starting_at = (ending_at - age_max)

        timestamp = starting_at.strftime("%FT%T")
      end

      buffer_lines = []
      buffer_size =  1 << 16
      File.open(path) do |file|
        if file.stat.size < buffer_size
          buffer_size = file.stat.size
        end

        file.seek(-buffer_size, File::SEEK_END)
        seek_position = buffer_size

        while buffer_lines.length <= lines
          buffer = file.read(buffer_size)
          line_list = buffer.split("\n")

          if timestamp.nil?
            buffer_lines = buffer_lines + line_list
          elsif
            line_list.each do |line|
              if (t = line.match(regexp_timestamp)) && (t[0] > timestamp)
                buffer_lines.push line
              end
            end
          end

          seek_position = seek_position + buffer_size
          break if seek_position > file.stat.size
          file.seek(2 * -buffer_size, File::SEEK_CUR)
        end

        file.close
      end

      buffer_lines.first(lines)
    end

    def _http_get_line(path, lines, options)
      raise 'Unknown http request type' unless ['get', 'post'].include? options['http_type']
    end
  end
end
