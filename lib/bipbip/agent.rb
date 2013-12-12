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

      Bipbip.logger.warn 'No services configured' if @services.empty?
      Bipbip.logger.warn 'No storages configured' if @storages.empty?

      plugin_instances = @services.map do |service|
        name = service['plugin'].to_s
        config = service.reject { |key, value| ['plugin'].include?(key) }
        Bipbip::Plugin.factory(name, config, @frequency)
      end

      storages_instances = @storages.map do |storage|
        name = storage['name'].to_s
        config = storage.reject { |key, value| ['name'].include?(key) }
        Bipbip::Storage.factory(name, config)
      end

      storages_instances.each do |storage|
        plugin_instances.each do |plugin|
          Bipbip.logger.info "Setting up plugin #{plugin.name} for storage #{storage.name}"
          storage.setup_plugin(plugin)
        end
      end

      ['INT', 'TERM'].each { |sig| trap(sig) {
        Thread.new { interrupt }
      } }

      plugin_instances.each do |plugin|
        Bipbip.logger.info "Starting plugin #{plugin.name} with config #{plugin.config}"
        @plugin_pids.push plugin.run(storages_instances)
      end

      while true
        sleep 1
      end
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
        @services += files.map { |file| YAML.load(File.open(file)) }
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
