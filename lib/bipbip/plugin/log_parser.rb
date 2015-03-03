require 'rb-inotify'

module Bipbip

  class Plugin::LogParser < Plugin

    def metrics_schema
      config['matchers'].map do |matcher|
        {:name => matcher['name'], :type => 'gauge', :unit => 'Boolean'}
      end
    end

    def monitor
      unless IO.select([notifier.to_io], [], [], 0).nil?
        n = notifier
        begin
          n.process
        rescue NoMethodError => e
          # Ignore errors from closed notifier - see https://github.com/nex3/rb-inotify/issues/41
          raise e unless n.watchers.empty?
        end
      end

      lines = @lines.entries
      @lines.clear

      Hash[
        config['matchers'].map do |matcher|
          name = matcher['name']
          regexp = Regexp.new(matcher['regexp'])
          value = lines.reject { |line| line.match(regexp).nil? }.length
          [name, value]
        end
      ]
    end

    private

    def notifier
      if @notifier.nil?
        @notifier = create_notifier
        @lines = []
        @size = File.stat(config['path']).size
      end
      @notifier
    end

    def create_notifier
      # Including the "attrib" event, because on some systems "unlink" triggers "attrib", but then the inode's deletion doesn't trigger "delete_self"
      events = [:modify, :delete_self, :move_self, :unmount, :attrib]
      notifier = INotify::Notifier.new
      notifier.watch(config['path'], *events) do |event|
        if event.flags.include?(:modify)
          roll_file
        else
          log(Logger::WARN, "File event `#{event.flags.join(',')}` detected, resetting notifier")
          reset_notifier
        end
      end
      notifier
    end

    def reset_notifier
      unless @notifier.nil?
        @notifier.stop
        @notifier.close
        @notifier = nil

        # Run GC to make sure file descriptor is freed
        # See https://github.com/nex3/rb-inotify/pull/43
        GC.start
      end
    end

    def roll_file
      file = File.new(config['path'], 'r')
      if file.size != @size
        file.seek(@size)
        @lines.push(*file.readlines)
        @size = file.size
      end
      file.close
    end

  end
end
