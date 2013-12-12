module Bipbip

  class Storage::Copperegg < Storage

    def initialize(name, config)
      super(name, config)
      CopperEgg::Api.apikey = config['api_key']
    end

    def setup_plugin(plugin)
      @metric_groups ||= load_metric_groups
      @dashboards ||= load_dashboards

      metric_group = @metric_groups.detect { |m| m.name == plugin.name }
      if metric_group.nil? || !metric_group.is_a?(CopperEgg::MetricGroup)
        Bipbip.logger.info "Creating copperegg metric group `#{plugin.name}`"
        metric_group = CopperEgg::MetricGroup.new(:name => plugin.name, :label => plugin.name, :frequency => plugin.frequency)
      end
      metric_group.frequency = plugin.frequency
      metric_group.metrics = plugin.metrics_schema
      metric_group.save

      dashboard = @dashboards.detect { |d| d.name == plugin.name }
      if dashboard.nil?
        Bipbip.logger.info "Creating copperegg dashboard `#{plugin.name}`"
        metrics = metric_group.metrics || []
        CopperEgg::CustomDashboard.create(metric_group, :name => plugin.name, :identifiers => nil, :metrics => metrics)
      end
    end

    def store_sample(plugin, time, data)
      CopperEgg::MetricSample.save(plugin.name, plugin.metric_identifier, time.to_i, data)
    end

    def load_metric_groups
      Bipbip.logger.info 'Loading copperegg metric groups'
      metric_groups = CopperEgg::MetricGroup.find
      if metric_groups.nil?
        Bipbip.logger.fatal 'Cannot load copperegg metric groups'
        exit 1
      end
      metric_groups
    end

    def load_dashboards
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
