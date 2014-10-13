require 'uri'

module Bipbip

  TIMESTAMP_REGEXP = '^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}'

  class Plugin::LogParser < Plugin

    def initialize(name, config, frequency)
      @log_min_timestamp = Time.now - frequency.to_i

      super name, config, frequency
    end

    def metrics_schema
      [
          {:name => config['name'], :type => 'gauge', :unit => 'Boolean'}
      ]
    end

    def monitor
      {
          config['name'] => source_check
      }
    end

    private

    def source_check
      [0].tap { |m|
        _get_lines.each do |line|
          m[0] += ((line.match(Regexp.new(config['regexp_text']))).nil?) ? 0 : 1
        end
      }.first
    end

    def source_uri
      @source_uri ||= [0].tap { |u|
        u[0] = URI(config['uri'])
        raise 'URI is not valid. Supported uri `file` type only.' unless ['file'].include? u[0].scheme
      }.first
    end

    def source_type
      source_uri.scheme
    end

    def source_path
      source_uri.path
    end

    def _get_lines
      _file_get_lines
    end

    def _file_get_lines
      raise 'File does not exist' unless File.exists?(source_path)

      regexp_timestamp = config.key?('regexp_timestamp') ? Regexp.new(config['regexp_timestamp']) : TIMESTAMP_REGEXP

      [].tap do |b|

        buffer_size =  1 << 16
        entry_min_timestamp = @log_min_timestamp.strftime("%FT%T")

        File.open(source_path) do |file|
          # resize buffer if file smaller than buffer
          if file.stat.size < buffer_size
            buffer_size = file.stat.size
          end

          file.seek(-buffer_size, File::SEEK_END)

          while file.pos > -1
            buffer = file.read(buffer_size)
            line_list = buffer.split("\n")

            # Remove first line as can be incomplete
            # due to seeking backward with
            # buffer_size steps
            first_line = line_list.shift
            offset = first_line.length

            line_count = b.length
            line_list.each do |line|
              if (t = line.match(regexp_timestamp)) && (t[0] > entry_min_timestamp)
                line_timestamp = DateTime.parse(t[0])
                @log_min_timestamp = line_timestamp if line_timestamp > @log_min_timestamp
                b.push line
              end
            end

            break if line_count == b.length

            backward_step = 2 * -buffer_size + offset
            break if file.pos + backward_step <= 0
            file.seek(backward_step, File::SEEK_CUR)
          end

          file.close
        end
      end
    end
  end
end
