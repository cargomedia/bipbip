module Bipbip

  class Agent

    PLUGIN_RESPAWN_DELAY = 5

    attr_accessor :plugins
    attr_accessor :storages

    def initialize(config_file = nil)
      @plugins = []
      @storages = []

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

      ['INT', 'TERM'].each { |sig| trap(sig) {
        Thread.new do
          interrupt
          exit
        end
      } }

      @plugins.each do |plugin|
        Bipbip.logger.info "Starting plugin #{plugin.name} with config #{plugin.config}"
        plugin.run(@storages)
      end

      @interrupted = false
      until @interrupted
        pid = Process.wait(-1)
        plugin = plugin_by_pid(pid)
        Bipbip.logger.error "Plugin #{plugin.name} with config #{plugin.config} died. Respawning..."
        sleep(PLUGIN_RESPAWN_DELAY)
        plugin.run(@storages)
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
          'services' => [],
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
        plugin_config = service.reject { |key, value| ['plugin', 'frequency', 'metric_group'].include?(key) }
        Bipbip::Plugin.factory(plugin_name, plugin_config, frequency, metric_group)
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

      Bipbip.logger.info 'Interrupt, killing plugin processes...'
      @plugins.each do |plugin|
        Process.kill('TERM', plugin.pid) if Process.exists?(plugin.pid)
      end

      Bipbip.logger.info 'Waiting for all plugin processes to exit...'
      Process.waitall
    end

    private

    def plugin_by_pid(pid)
      plugin = @plugins.find { |plugin| plugin.pid == pid }
      if plugin.nil?
        raise "Cannot find plugin with pid #{pid}"
      end
      plugin
    end
  end
end
