module Bipbip

  class Agent

    def initialize(config_file = nil)
      @plugin_pids = []
      @logfile = STDOUT
      @loglevel = 'INFO'
      @frequency = 60
      @services = []
      @storages = []

      load_config(config_file) if config_file
    end

    def run
      Bipbip.logger = Logger.new(@logfile)
      Bipbip.logger.level = Logger::const_get(@loglevel)
      Bipbip.logger.info 'Startup...'

      if ![5, 15, 60, 300, 900, 3600, 21600].include?(@frequency)
        Bipbip.logger.fatal "Invalid frequency: #{@frequency}"
        exit 1
      end

      ['INT', 'TERM'].each { |sig| trap(sig) {
        Thread.new { interrupt }
      } }

      plugin_instances = {}
      services_instances = @services.map do |service|
        name = service['plugin'].to_s
        config = service.reject { |key, value| ['plugin'].include?(key) }
        if plugin_instances.has_key?(name)
          plugin = plugin_instances[name]
        else
          plugin = plugin_instances[name] = plugin_factory(name, @frequency)
        end
        Bipbip::Service.new(plugin, config)
      end

      storages_instances = @storages.map do |storage|
        name = storage['name'].to_s
        config = storage.reject { |key, value| ['name'].include?(key) }
        storage_factory(name, config)
      end

      storages_instances.each do |storage|
        plugin_instances.each do |name, plugin|
          storage.setup_plugin(plugin)
        end
      end

      services_instances.each do |service|
        @plugin_pids.push service.run
      end

      while true
        sleep 1
      end
    end



    def plugin_factory(name, frequency)
      require "bipbip/plugin/#{Bipbip::Helper.name_to_filename(name)}"
      Plugin::const_get(Bipbip::Helper.name_to_classname(name)).new(name, frequency)
    end

    def storage_factory(name, config)
      require "bipbip/storage/#{Bipbip::Helper.name_to_filename(name)}"
      Storage::const_get(Bipbip::Helper.name_to_classname(name)).new(name, config)
    end

    def load_config(config_file)
      config = YAML.load(File.open(config_file))
      if config.has_key?('logfile')
        @logfile = config['logfile'].to_s
      end
      if config.has_key?('loglevel')
        @loglevel = config['loglevel'].to_s
      end
      if config.has_key?('frequency')
        @frequency = config['frequency'].to_i
      end
      if config.has_key?('services')
        @services = config['services'].to_a
      end
      if config.has_key?('include')
        include_path = File.expand_path(config['include'].to_s, File.dirname(config_file))
        files = Dir[include_path + '/**/*.yaml', include_path + '/**/*.yml']
        @services += files.map {|file| YAML.load(File.open(file))}
      end
      if config.has_key?('storages')
        @storages = config['storages'].to_a
      end
    end

    def interrupt
      Bipbip.logger.info 'Interrupt, killing plugin processes...'
      @plugin_pids.each { |pid| Process.kill('TERM', pid) }

      Bipbip.logger.info 'Waiting for all plugin processes to exit...'
      Process.waitall

      Bipbip.logger.info 'Exiting'
      exit
    end
  end
end
