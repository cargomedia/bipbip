module CoppereggAgents

  class Agent

    def run
      config = YAML.load(File.open('config.yml'))

      CopperEgg::Api.apikey = config['copperegg']['apikey']
      CopperEgg::Api.host = config['copperegg']['host'] if !config['copperegg']['host'].nil?
      frequency = config['copperegg']['frequency']
      services = config['copperegg']['services']

      frequency = 60 if ![5, 15, 60, 300, 900, 3600, 21600].include?(frequency)
      log "Update frequency set to #{frequency}s."

      #metric_groups = CopperEgg::MetricGroup.find
      #dashboards = CopperEgg::CustomDashboard.find



      services.each do |service|
        service_config = config[service]
        service_name = service_config['name']
        agent = Plugin::const_get(service_name).new(service_config)
        agent.monitor
          #begin
          #  log "Checking for existence of metric group for #{service}"
          #  metric_group = metric_groups.detect {|m| m.name == service_config['name']}
          #  metric_group = ensure_metric_group(metric_group, service)
          #  raise "Could not create a metric group for #{service}" if metric_group.nil?
          #
          #  log "Checking for existence of #{service} Dashboard"
          #  dashboard = dashboards.detect {|d| d.name == @config[service]["dashboard"]} || create_dashboard(service, metric_group)
          #  log "Could not create a dashboard for #{service}" if dashboard.nil?
          #rescue => e
          #  log e.message
          #  log "#{e.inspect}"
          #  log e.backtrace[0..30].join("\n") if @debug
          #  next
          #end
          #child_pid = fork {
          #  trap("INT") { child_interrupt if !@interrupted }
          #  trap("TERM") { child_interrupt if !@interrupted }
          #
          #  last_failure = 0
          #  retries = MAX_RETRIES
          #  begin
          #    # reset retries counter if last failure was more than 10 minutes ago
          #    monitor_service(service, metric_group)
          #  rescue => e
          #    puts "Error monitoring #{service}.  Retying (#{retries}) more times..."
          #    log "#{e.inspect}"
          #    log e.backtrace[0..30].join("\n") if @debug
          #    # updated 7-9-2013, removed the # before if @debug
          #    raise e if @debug
          #    sleep 2
          #    retries -= 1
          #    retries = MAX_RETRIES if Time.now.to_i - last_failure > 600
          #    last_failure = Time.now.to_i
          #    retry if retries > 0
          #    raise e
          #  end
          #}
          #@worker_pids.push child_pid
      end

    end

    def log(str)
      begin
        str.split("\n").each do |line|
          puts "#{Time.now.strftime('%Y/%m/%d %H:%M:%S')}: #{line}"
        end
        $stdout.flush
      rescue Exception => e
        # do nothing -- just catches unimportant errors when we kill the process
        # and it's in the middle of logging or flushing.
      end
    end
  end
end
