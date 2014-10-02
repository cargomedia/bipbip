require 'uri'

module Bipbip

  class Plugin::LogParser < Plugin

    def initialize(name, config, frequency)
      @start_at = Time.now - frequency.to_i
      @source_uri = nil

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
        raise 'URI is not valid' unless ['file'].include? u[0].scheme
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
      raise 'Regexp for timestamp is not set' unless config.key?('regexp_timestamp')

      regexp_timestamp = Regexp.new(config['regexp_timestamp'])

      [].tap do |b|

        buffer_size =  1 << 16
        start_timestamp = @start_at.strftime("%FT%T")

        File.open(source_path) do |file|
          if file.stat.size < buffer_size
            buffer_size = file.stat.size
          end

          file.seek(-buffer_size, File::SEEK_END)
          seek_position = buffer_size

          # make resistant for line braking

          while seek_position <= file.stat.size
            buffer = file.read(buffer_size)
            line_list = buffer.split("\n")

            line_count = b.length
            line_list.each do |line|
              if (t = line.match(regexp_timestamp)) && (t[0] > start_timestamp)
                line_timestamp = DateTime.parse(t[0])
                @start_at = line_timestamp if line_timestamp > @start_at

                b.push line
              end
            end

            break if line_count == b.length

            seek_position = seek_position + buffer_size
            break if seek_position > file.stat.size
            file.seek(2 * -buffer_size, File::SEEK_CUR)
          end

          file.close
        end
      end
    end
  end
end
