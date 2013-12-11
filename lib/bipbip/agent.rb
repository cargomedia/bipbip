module Bipbip

  class Agent

    def initialize(config_file)
      @plugin_pids = []
      @logfile = STDOUT
      @loglevel = 'INFO'
      @frequency = 60
      @services = []
      @copperegg_api_key

      load_config(config_file)
    end

    def run
      Bipbip.logger = Logger.new(@logfile)
      Bipbip.logger.level = Logger::const_get(@loglevel)
      Bipbip.logger.info 'Startup...'

      Bipbip.logger.info "Using CopperEgg API key `#{@copperegg_api_key}`"
      CopperEgg::Api.apikey = @copperegg_api_key

      if ![5, 15, 60, 300, 900, 3600, 21600].include?(@frequency)
        Bipbip.logger.fatal "Invalid frequency: #{@frequency}"
        exit 1
      end

      ['INT', 'TERM'].each { |sig| trap(sig) {
        Thread.new { interrupt }
      } }

      metric_groups = get_copperegg_metric_groups
      dashboards = get_copperegg_dashboards

      plugin_names = @services.map { |service| service['plugin'] }
      plugin_names.each do |plugin_name|
        plugin = plugin_factory(plugin_name)

        metric_group = metric_groups.detect { |m| m.name == plugin_name }
        if metric_group.nil? || !metric_group.is_a?(CopperEgg::MetricGroup)
          Bipbip.logger.info "Creating metric group `#{plugin_name}`"
          metric_group = CopperEgg::MetricGroup.new(:name => plugin_name, :label => plugin_name, :frequency => @frequency)
        end
        metric_group.frequency = @frequency
        metric_group.metrics = plugin.metrics_schema
        metric_group.save

        dashboard = dashboards.detect { |d| d.name == plugin_name }
        if dashboard.nil?
          Bipbip.logger.info "Creating dashboard `#{plugin_name}`"
          metrics = metric_group.metrics || []
          CopperEgg::CustomDashboard.create(metric_group, :name => plugin_name, :identifiers => nil, :metrics => metrics)
        end
      end

      @services.each do |service|
        plugin_name = service['plugin']
        plugin = plugin_factory(plugin_name)
        service_config = service.select { |key, value| !['plugin'].include?(key) }
        Bipbip.logger.info "Starting plugin #{plugin_name}"
        @plugin_pids.push plugin.run(service_config, @frequency)
      end

      while true
        sleep 1
      end
    end

    def get_copperegg_metric_groups
      Bipbip.logger.info 'Loading metric groups'
      metric_groups = CopperEgg::MetricGroup.find
      if metric_groups.nil?
        Bipbip.logger.fatal 'Cannot load metric groups'
        exit 1
      end
      metric_groups
    end

    def get_copperegg_dashboards
      Bipbip.logger.info 'Loading dashboards'
      dashboards = CopperEgg::CustomDashboard.find
      if dashboards.nil?
        Bipbip.logger.fatal 'Cannot load dashboards'
        exit 1
      end
      dashboards
    end

    def plugin_factory(plugin_name)
      file_name = plugin_name.tr('-', '_')
      require "bipbip/plugin/#{file_name}"

      class_name = plugin_name.split('-').map{|w| w.capitalize}.join
      Plugin::const_get(class_name).new(plugin_name)
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
      if config.has_key?('copperegg')
        config_copperegg = config['copperegg']
        if config_copperegg.has_key?('apikey')
          @copperegg_api_key = config_copperegg['apikey']
        end
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
