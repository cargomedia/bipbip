module Bipbip

  class Storage::Copperegg < Storage

    def initialize(name, config)
      super(name, config)
      CopperEgg::Api.apikey = config['api_key']
    end

    def setup_plugin(plugin)
      @metric_groups ||= _load_metric_groups
      @dashboards ||= _load_dashboards

      if ![5, 15, 60, 300, 900, 3600, 21600].include?(plugin.frequency)
        Bipbip.logger.fatal "Copperegg cannot use frequency #{plugin.frequency}"
        exit 1
      end

      metric_group = @metric_groups.detect { |m| m.name == plugin.metric_group }
      if metric_group.nil? || !metric_group.is_a?(CopperEgg::MetricGroup)
        Bipbip.logger.info "Creating copperegg metric group `#{plugin.metric_group}`"
        metric_group = CopperEgg::MetricGroup.new(:name => plugin.metric_group, :label => plugin.metric_group, :frequency => plugin.frequency)
      end
      metric_group.frequency = plugin.frequency
      metric_group.metrics = plugin.metrics_schema.map do |sample|
        {
            :name => sample[:name],
            :type => 'ce_' + sample[:type],
            :unit => sample[:unit],
        }
      end
      metric_group.save

      dashboard = @dashboards.detect { |d| d.name == plugin.metric_group }
      if dashboard.nil?
        Bipbip.logger.info "Creating copperegg dashboard `#{plugin.metric_group}`"
        metrics = metric_group.metrics || []
        CopperEgg::CustomDashboard.create(metric_group, :name => plugin.metric_group, :identifiers => nil, :metrics => metrics)
      end
    end

    def store_sample(plugin, time, data)
      CopperEgg::MetricSample.save(plugin.metric_group, plugin.source_identifier, time.to_i, data)
    end

    def _load_metric_groups
      Bipbip.logger.info 'Loading copperegg metric groups'
      metric_groups = CopperEgg::MetricGroup.find
      if metric_groups.nil?
        Bipbip.logger.fatal 'Cannot load copperegg metric groups'
        exit 1
      end
      metric_groups
    end

    def _load_dashboards
      Bipbip.logger.info 'Loading copperegg dashboards'
      dashboards = CopperEgg::CustomDashboard.find
      if dashboards.nil?
        Bipbip.logger.fatal 'Cannot load copperegg dashboards'
        exit 1
      end
      dashboards
    end

  end
end
