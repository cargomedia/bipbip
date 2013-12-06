module CoppereggAgents

  class Agent

    def run
      config = YAML.load(File.open('config.yml'))

      p config

      CopperEgg::Api.apikey = config['copperegg']['apikey']
      CopperEgg::Api.host = config['copperegg']['host'] if !config['copperegg']['host'].nil?
      frequency = config['copperegg']['frequency']
      services = config['copperegg']['services']

      frequency = 60 if ![5, 15, 60, 300, 900, 3600, 21600].include?(frequency)
      log "Update frequency set to #{frequency}s."

      metric_groups = CopperEgg::MetricGroup.find
      dashboards = CopperEgg::CustomDashboard.find

      agent = Plugin::Memcached.new
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
