module Bipbip

  class Agent

    attr_accessor :plugins
    attr_accessor :storages

    def initialize(config_file = nil)
      @plugins = []
      @storages = []
      @plugin_pids = []

      load_config(config_file) if config_file
    end

    def run
      Bipbip.logger.info 'Startup...'
      Bipbip.logger.warn 'No services configured' if @plugins.empty?
      Bipbip.logger.warn 'No storages configured' if @storages.empty?

      @storages.each do |storage|
        @plugins.each do |plugin|
          Bipbip.logger.info "Setting up plugin #{plugin.name} for storage #{storage.name}"
          storage.setup_plugin(plugin)
        end
      end

      ['INT', 'TERM'].each { |sig| trap(sig) {
        Thread.new { interrupt }
      } }

      @plugins.each do |plugin|
        Bipbip.logger.info "Starting plugin #{plugin.name} with config #{plugin.config}"
        @plugin_pids.push plugin.run(@storages)
      end

      while true
        sleep 1
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
        service_name = service['plugin'].to_s
        frequency = service['frequency'].nil? ? config['frequency'] : service['frequency'].to_i
        service_config = service.reject { |key, value| ['plugin','frequency'].include?(key) }
        Bipbip::Plugin.factory(service_name, service_config, frequency)
      end

      storages = config['storages'].to_a
      @storages = storages.map do |storage|
        storage_name = storage['name'].to_s
        storage_config = storage.reject { |key, value| ['name'].include?(key) }
        Bipbip::Storage.factory(storage_name, storage_config)
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
