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

      raise 'No services configured' if @plugins.empty?

      @storages.each do |storage|
        @plugins.each do |plugin|
          Bipbip.logger.info "Setting up plugin #{plugin.name} for storage #{storage.name}"
          storage.setup_plugin(plugin)
        end
      end

      @plugins.each do |plugin|
        Bipbip.logger.info "Starting plugin #{plugin.name} with config #{plugin.config}"
        start_plugin(plugin, @storages)
      end

      loop do
        thread = ThreadsWait.new(@threads).next_wait
        @threads.delete(thread)
        plugin = thread['plugin']

        Bipbip.logger.error "Plugin #{plugin.name} with config #{plugin.config} terminated. Restarting..."
        interruptible_sleep(PLUGIN_RESPAWN_DELAY)

        # Re-instantiate plugin to get rid of existing database-connections etc
        plugin_new = Bipbip::Plugin.factory_from_plugin(plugin)
        @plugins.delete(plugin)
        @plugins.push(plugin_new)
        start_plugin(plugin_new, @storages)
      end
    end

    private

    # @param [Bipbip::Plugin] plugin
    # @param [Array<Bipbip::Storage>] storages
    def start_plugin(plugin, storages)
      thread = Thread.new { plugin.run(storages) }
      thread['plugin'] = plugin
      @threads.push(thread)
    end
  end
end
