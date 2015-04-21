module Bipbip

  class Config

    attr_reader :plugins
    attr_reader :storages
    attr_reader :logger

    # @param [String] file_path
    # @return [Bipbip::Config]
    def self.factory_from_file(file_path)
      config = YAML.load(File.open(file_path))
      config = {
        'logfile' => STDOUT,
        'loglevel' => 'INFO',
        'frequency' => 60,
        'include' => nil,
        'services' => [],
        'tags' => [],
      }.merge(config)

      logger = Logger.new(config['logfile'])
      logger.level = Logger::const_get(config['loglevel'])

      plugins_config = config['services'].to_a
      if config['include']
        include_path = File.expand_path(config['include'].to_s, File.dirname(file_path))

        files = Dir[include_path + '/**/*.yaml', include_path + '/**/*.yml']
        plugins_config += files.map { |file| YAML.load(File.open(file)) }
      end

      plugins = plugins_config.map do |service|
        plugin_name = service['plugin']
        metric_group = service['metric_group']
        frequency = service['frequency'].nil? ? config['frequency'] : service['frequency']
        tags = config['tags'].to_a + service['tags'].to_a
        plugin_config = service.reject { |key, value| ['plugin', 'frequency', 'tags', 'metric_group'].include?(key) }
        Bipbip::Plugin.factory(plugin_name, plugin_config, frequency, tags, metric_group)
      end

      storages_config = config['storages'].to_a
      storages = storages_config.map do |storage|
        storage_name = storage['name'].to_s
        storage_config = storage.reject { |key, value| ['name'].include?(key) }
        Bipbip::Storage.factory(storage_name, storage_config)
      end

      Bipbip::Config.new(plugins, storages, logger)
    end

    # @param [Array<Bipbip::Plugin>] [plugins]
    # @param [Array<Bipbip::Storage>] [storages]
    # @param [Logger] [logger]
    def initialize(plugins = nil, storages = nil, logger = nil)
      @plugins = plugins || []
      @storages = storages || []
      @logger = logger || Logger.new(STDOUT)
    end

  end
end
