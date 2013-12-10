module Bipbip

  class Agent

    def initialize
      @plugin_pids = []
    end

    def run(config_file)
      config = YAML.load(File.open(config_file))

      Bipbip.logger = Logger.new(STDOUT)
      Bipbip.logger.level = Logger::const_get(config['loglevel'] || 'INFO')
      Bipbip.logger.info 'Startup...'

      CopperEgg::Api.apikey = config['copperegg']['apikey']
      CopperEgg::Api.host = config['copperegg']['host'] if !config['copperegg']['host'].nil?
      frequency = config['copperegg']['frequency'].to_i

      if ![5, 15, 60, 300, 900, 3600, 21600].include?(frequency)
        Bipbip.logger.fatal "Invalid frequency: #{frequency}"
        exit
      end

      ['INT', 'TERM'].each { |sig| trap(sig) {
        Thread.new { interrupt }
      } }

      services = config['services'].to_a
      if config.has_key?('include')
        include_path = File.expand_path(config['include'], File.dirname(config_file))
        services += load_include_configs(include_path)
      end

      metric_groups = load_metric_groups
      dashboards = load_dashboards

      plugin_names = services.map { |service| service['plugin'] }
      plugin_names.each do |plugin_name|
        plugin = Plugin::const_get(plugin_name).new

        metric_group = metric_groups.detect { |m| m.name == plugin_name }
        if metric_group.nil? || !metric_group.is_a?(CopperEgg::MetricGroup)
          Bipbip.logger.info "Creating metric group `#{plugin_name}`"
          metric_group = CopperEgg::MetricGroup.new(:name => plugin_name, :label => plugin_name, :frequency => frequency)
        end
        metric_group.frequency = frequency
        metric_group.metrics = plugin.metrics_schema
        metric_group.save

        dashboard = dashboards.detect { |d| d.name == plugin_name }
        if dashboard.nil?
          Bipbip.logger.info "Creating dashboard `#{plugin_name}`"
          metrics = metric_group.metrics || []
          CopperEgg::CustomDashboard.create(metric_group, :name => plugin_name, :identifiers => nil, :metrics => metrics)
        end
      end

      services.each do |service|
        plugin_name = service['plugin']
        Bipbip.logger.info "Starting plugin #{plugin_name}"
        plugin = Plugin::const_get(plugin_name).new
        @plugin_pids.push plugin.run(service, frequency)
      end

      p Process.waitall
    end

    def load_metric_groups
      Bipbip.logger.info 'Loading metric groups'
      metric_groups = CopperEgg::MetricGroup.find
      if metric_groups.nil?
        raise 'Cannot load metric groups'
      end
      metric_groups
    end

    def load_dashboards
      Bipbip.logger.info 'Loading dashboards'
      dashboards = CopperEgg::CustomDashboard.find
      if dashboards.nil?
        raise 'Cannot load dashboards'
      end
      dashboards
    end

    def load_include_configs(directory)
      files = Dir[directory + '/**/*.yaml', directory + '/**/*.yml']
      services = files.map {|file| YAML.load(File.open(file))}
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
