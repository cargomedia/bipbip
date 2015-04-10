module Bipbip

  class Agent
    include InterruptibleSleep

    PLUGIN_RESPAWN_DELAY = 5

    attr_accessor :plugins
    attr_accessor :storages
    attr_accessor :threads

    def initialize(config_file = nil)
      @plugins = []
      @storages = []
      @threads = []

      load_config(config_file) if config_file
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

    def load_config(config_file)
      config = YAML.load(File.open(config_file))
      config = {
        'logfile' => STDOUT,
        'loglevel' => 'INFO',
        'frequency' => 60,
        'include' => nil,
        'services' => [],
        'tags' => [],
      }.merge(config)

      Bipbip.logger = Logger.new(config['logfile'])
      Bipbip.logger.level = Logger::const_get(config['loglevel'])

      services = config['services'].to_a
      if config['include']
        include_path = File.expand_path(config['include'].to_s, File.dirname(config_file))

        files = Dir[include_path + '/**/*.yaml', include_path + '/**/*.yml']
        services += files.map { |file| YAML.load(File.open(file)) }
      end

      @plugins = services.map do |service|
        plugin_name = service['plugin']
        metric_group = service['metric_group']
        frequency = service['frequency'].nil? ? config['frequency'] : service['frequency']
        tags = config['tags'].to_a + service['tags'].to_a
        plugin_config = service.reject { |key, value| ['plugin', 'frequency', 'tags', 'metric_group'].include?(key) }
        Bipbip::Plugin.factory(plugin_name, plugin_config, frequency, tags, metric_group)
      end

      storages = config['storages'].to_a
      @storages = storages.map do |storage|
        storage_name = storage['name'].to_s
        storage_config = storage.reject { |key, value| ['name'].include?(key) }
        Bipbip::Storage.factory(storage_name, storage_config)
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
