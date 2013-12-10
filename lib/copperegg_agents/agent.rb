module CoppereggAgents

  class Agent

    def initialize
      @plugin_pids = []
    end

    def run(config_file)
      config = YAML.load(File.open(config_file))

      CoppereggAgents.logger = Logger.new(STDOUT)
      CoppereggAgents.logger.level = Logger::const_get(config['loglevel'] || 'INFO')
      CoppereggAgents.logger.info 'Startup...'

      CopperEgg::Api.apikey = config['copperegg']['apikey']
      CopperEgg::Api.host = config['copperegg']['host'] if !config['copperegg']['host'].nil?
      frequency = config['copperegg']['frequency'].to_i

      if ![5, 15, 60, 300, 900, 3600, 21600].include?(frequency)
        CoppereggAgents.logger.fatal "Invalid frequency: #{frequency}"
        exit
      end

      ['INT', 'TERM'].each { |sig| trap(sig) {
        Thread.new { interrupt }
      } }

      services = config['services']

      metric_groups = load_metric_groups
      dashboards = load_dashboards

      plugin_names = services.map { |service| service['plugin'] }
      plugin_names.each do |plugin_name|
        plugin = Plugin::const_get(plugin_name).new

        metric_group = metric_groups.detect { |m| m.name == plugin_name }
        if metric_group.nil? || !metric_group.is_a?(CopperEgg::MetricGroup)
          CoppereggAgents.logger.info "Creating metric group `#{plugin_name}`"
          metric_group = CopperEgg::MetricGroup.new(:name => plugin_name, :label => plugin_name, :frequency => frequency)
        end
        metric_group.frequency = frequency
        metric_group.metrics = plugin.metrics_schema
        metric_group.save

        dashboard = dashboards.detect { |d| d.name == plugin_name }
        if dashboard.nil?
          CoppereggAgents.logger.info "Creating dashboard `#{plugin_name}`"
          metrics = metric_group.metrics || []
          CopperEgg::CustomDashboard.create(metric_group, :name => plugin_name, :identifiers => nil, :metrics => metrics)
        end
      end

      services.each do |service|
        plugin_name = service['plugin']
        CoppereggAgents.logger.info "Starting plugin #{plugin_name}"
        plugin = Plugin::const_get(plugin_name).new
        @plugin_pids.push plugin.run(service, frequency)
      end

      p Process.waitall
    end

    def load_metric_groups
      CoppereggAgents.logger.info 'Loading metric groups'
      metric_groups = CopperEgg::MetricGroup.find
      if metric_groups.nil?
        raise 'Cannot load metric groups'
      end
      metric_groups
    end

    def load_dashboards
      CoppereggAgents.logger.info 'Loading dashboards'
      dashboards = CopperEgg::CustomDashboard.find
      if dashboards.nil?
        raise 'Cannot load dashboards'
      end
      dashboards
    end

    def interrupt
      CoppereggAgents.logger.info 'Interrupt, killing plugin processes...'
      @plugin_pids.each { |pid| Process.kill('TERM', pid) }

      CoppereggAgents.logger.info 'Waiting for all plugin processes to exit...'
      Process.waitall

      CoppereggAgents.logger.info 'Exiting'
      exit
    end
  end
end
