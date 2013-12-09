module CoppereggAgents

  class Agent

    def initialize
      @plugin_pids = []
    end

    def run
      config = YAML.load(File.open('config.yml'))

      CoppereggAgents.logger = Logger.new(STDOUT)
      CoppereggAgents.logger.level = Logger::const_get(config['loglevel'] || 'INFO')
      CoppereggAgents.logger.info 'Startup...'

      CopperEgg::Api.apikey = config['copperegg']['apikey']
      CopperEgg::Api.host = config['copperegg']['host'] if !config['copperegg']['host'].nil?
      frequency = config['copperegg']['frequency']

      if ![5, 15, 60, 300, 900, 3600, 21600].include?(frequency)
        CoppereggAgents.logger.fatal "Invalid frequency: #{frequency}"
        exit
      end

      ['INT', 'TERM'].each { |sig| trap(sig) {
        Thread.new { interrupt }
      } }

      metric_groups = CopperEgg::MetricGroup.find
      dashboards = CopperEgg::CustomDashboard.find

      services = config['services']

      services.each do |service_name, plugin_config|
        plugin_name = plugin_config['name']
        servers = plugin_config['servers']
        plugin = Plugin::const_get(plugin_name).new

        metric_group = metric_groups.detect { |m| m.name == plugin_name }
        if metric_group.nil? || !metric_group.is_a?(CopperEgg::MetricGroup)
          CoppereggAgents.logger.info "Creating metric group `#{plugin_name}`"
          metric_group = CopperEgg::MetricGroup.new(:name => plugin_name, :label => plugin_name, :frequency => frequency)
        else
          metric_group.frequency = frequency
        end
        plugin.configure_metric_group(metric_group)

        dashboard = dashboards.detect { |d| d.name == plugin_name }
        if dashboard.nil?
          CoppereggAgents.logger.info "Creating dashboard `#{plugin_name}`"
          metrics = metric_group.metrics || []
          CopperEgg::CustomDashboard.create(metric_group, :name => plugin_name, :identifiers => nil, :metrics => metrics)
        end

        servers.each do |server|
          CoppereggAgents.logger.info "Starting plugin `#{plugin_name}` for server `#{server}`"
          plugin_pid = plugin.run(server, frequency)
          @plugin_pids.push plugin_pid
        end
      end

      p Process.waitall
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
