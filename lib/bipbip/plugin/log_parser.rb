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

    def regexp_timestamp
      @regexp_timestamp ||= Regexp.new(config.fetch('regexp_timestamp', TIMESTAMP_REGEXP))
    end



    def lines
      [].tap do |b|

        buffer_size = 65536

        File.open(config['path']) do |file|
          file.seek(0, File::SEEK_END)

          _time = log_time_min
          while file.pos >= 0
            if file.pos < buffer_size
              buffer_size = file.pos
            end

            file.seek(-buffer_size, File::SEEK_CUR)

            line_list = file.read(buffer_size).split("\n")

            # Remove first line as can be incomplete
            # due to seeking backward with
            # buffer_size steps
            first_line = line_list.shift
            file.seek(-buffer_size + first_line.length, File::SEEK_CUR)

            a = line_list.select do |line|
              timestamp = line.match(regexp_timestamp)
              unless timestamp.nil?
                time = DateTime.parse(timestamp[0]).to_time
                if time >= log_time_min
                  1 == 1
                end
                if time > _time
                  _time = time
                end
              end
            end

            b.push(*line_list)

            break if line_list.empty?
          end

          self.log_time_min = _time
        end
      end
    end
  end
end
