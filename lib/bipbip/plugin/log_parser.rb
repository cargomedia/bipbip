require 'date'

module Bipbip

  TIMESTAMP_REGEXP = '^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}'

  class Plugin::LogParser < Plugin

    def metrics_schema
      [
          {:name => config['name'], :type => 'gauge', :unit => 'Boolean'}
      ]
    end

    def monitor
      {
          config['name'] => match_count
      }
    end

    private

    def match_count
      lines.reject { |line| line.match(Regexp.new(config['regexp_text'])).nil? }.length
    end

    def log_time_min
      @log_time_min ||= Time.now - @frequency.to_i
    end

    def log_time_min=(time)
      @log_time_min = time
    end

    def lines
      raise 'File does not exist' unless File.exists?(config['path'])

      regexp_timestamp = config.key?('regexp_timestamp') ? Regexp.new(config['regexp_timestamp']) : TIMESTAMP_REGEXP

      [].tap do |b|

        buffer_size = 1 << 16

        File.open(config['path']) do |file|
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
              timestamp = line.match(regexp_timestamp)
              unless timestamp.nil?
                time = DateTime.parse(timestamp[0]).to_time
                if time > log_time_min
                  self.log_time_min = time
                  b.push line
                end
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
