module CoppereggAgents

  class Agent
    def initialize
      @plugin_pids = []
    end

    def run
      config = YAML.load(File.open('config.yml'))

      CopperEgg::Api.apikey = config['copperegg']['apikey']
      CopperEgg::Api.host = config['copperegg']['host'] if !config['copperegg']['host'].nil?
      frequency = config['copperegg']['frequency']
      services = config['copperegg']['services']

      frequency = 60 if ![5, 15, 60, 300, 900, 3600, 21600].include?(frequency)
      Utils.log "Update frequency set to #{frequency}s."

      #metric_groups = CopperEgg::MetricGroup.find
      #dashboards = CopperEgg::CustomDashboard.find

      trap('INT') { interrupt }
      trap('TERM') { interrupt }

      services.each do |service|
        plugin_config = config[service]
        plugin_name = plugin_config['name']
        servers = plugin_config['servers']
        plugin = Plugin::const_get(plugin_name).new
        plugin.ensure_metric_group
        servers.each do |server|
          plugin_pid = plugin.run(server, frequency)
          @plugin_pids.push plugin_pid
        end
      end

      p Process.waitall
    end

    def interrupt
      Utils.log 'Interrupt, killing plugin processes...'

      @plugin_pids.each do |pid|
        Process.kill 'TERM', pid
      end

      Utils.log 'Waiting for all plugin processes to exit...'
      Process.waitall

      Utils.log 'Exiting cleanly'
      exit
    end
  end
end
