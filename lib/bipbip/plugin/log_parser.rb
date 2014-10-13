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
      time_first = nil

      lines = lines_backwards.take_while do |line|
        timestamp_match = line.match(regexp_timestamp)
        raise "Line doesn't match `#{regexp_timestamp}`: `#{line}`" if timestamp_match.nil?
        time = DateTime.parse(timestamp_match[0]).to_time
        time_first ||= time
        (time > log_time_min)
      end

      self.log_time_min = time_first unless time_first.nil?

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

    def lines_backwards
      buffer_size = 65536

      Enumerator.new do |yielder|
        File.open(config['path']) do |file|
          file.seek(0, File::SEEK_END)

          while file.pos > 0
            buffer_size = file.pos if file.pos < buffer_size

            file.seek(-buffer_size, File::SEEK_CUR)
            buffer = file.read(buffer_size)
            file.seek(-buffer_size, File::SEEK_CUR)

            line_list = buffer.each_line.entries

            if file.pos != 0
              # Remove first line as can be incomplete
              # due to seeking backward with buffer_size steps
              first_line = line_list.shift
              raise "Line length exceeds buffer size `#{buffer_size}`" if first_line.length == buffer_size
              file.seek(first_line.length, File::SEEK_CUR)
            end

            line_list.reverse.each do |line|
              yielder.yield(line)
            end
          end
        end
      end
    end

  end
end
