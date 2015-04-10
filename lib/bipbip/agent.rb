module Bipbip

  class Agent
    include InterruptibleSleep

    PLUGIN_RESPAWN_DELAY = 5

    attr_accessor :plugins
    attr_accessor :storages
    attr_accessor :threads

    # @param [Bipbip::Config] config
    def initialize(config)
      @plugins = config.plugins
      @storages = config.storages
      Bipbip.logger = config.logger

      @threads = []
    end

    def run
      Bipbip.logger.info 'Startup...'
      Bipbip.logger.warn 'No storages configured' if @storages.empty?

      if @plugins.empty?
        raise 'No services configured'
      end

      @storages.each do |storage|
        @plugins.each do |plugin|
          Bipbip.logger.info "Setting up plugin #{plugin.name} for storage #{storage.name}"
          storage.setup_plugin(plugin)
        end
      end

      ['INT', 'TERM'].each do |sig|
        trap(sig) do
          Bipbip.logger.info "Received signal #{sig}, interrupting..."
          interrupt
        end
      end

      @plugins.each do |plugin|
        Bipbip.logger.info "Starting plugin #{plugin.name} with config #{plugin.config}"
        @threads.push(plugin.run(@storages))
      end

      @interrupted = false
      until @interrupted
        thread = ThreadsWait.new(@threads).next_wait
        plugin = plugin_by_thread(thread)
        next if @interrupted

        Bipbip.logger.error "Plugin #{plugin.name} with config #{plugin.config} terminated. Restarting..."
        interruptible_sleep(PLUGIN_RESPAWN_DELAY)
        next if @interrupted

        plugin_new = Bipbip::Plugin.factory_from_plugin(plugin)
        thread_new = plugin_new.run(@storages)
        @plugins.delete(plugin)
        @plugins.push(plugin_new)
        @threads.delete(thread)
        @threads.push(thread_new)
      end
    end

    def interrupt
      @interrupted = true
      @threads.each do |thread|
        thread.terminate
      end
      interrupt_sleep
    end

    private

    # @param [Thread] thread
    # @return [Bipbip::Plugin]
    def plugin_by_thread(thread)
      plugin = @plugins.find { |plugin| plugin.thread == thread }
      if plugin.nil?
        raise "Cannot find plugin by thread #{thread}"
      end
      plugin
    end
  end
end
