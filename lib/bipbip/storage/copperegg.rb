module Bipbip
  class Storage::Copperegg < Storage
    def initialize(name, config)
      super(name, config)
      ::Copperegg::Revealmetrics::Api.apikey = config['api_key']
    end

    def setup_plugin(plugin)
      @metric_groups ||= _load_metric_groups
      @dashboards ||= _load_dashboards
      @tags ||= _load_tags

      unless [5, 15, 60, 300, 900, 3600, 21_600].include?(plugin.frequency)
        raise "Cannot use frequency #{plugin.frequency}"
      end

      metric_group = @metric_groups.detect { |m| m.name == plugin.metric_group }
      if metric_group.nil? || !metric_group.is_a?(::Copperegg::Revealmetrics::MetricGroup)
        log(Logger::INFO, "Creating metric group `#{plugin.metric_group}`")
        metric_group = ::Copperegg::Revealmetrics::MetricGroup.new(name: plugin.metric_group, label: plugin.metric_group, frequency: plugin.frequency)
      end
      metric_group.frequency = plugin.frequency
      metric_group.metrics = plugin.metrics_schema.map do |sample|
        {
          name: sample[:name],
          type: 'ce_' + sample[:type],
          unit: sample[:unit]
        }
      end
      log(Logger::INFO, "Updating metric group `#{plugin.metric_group}`")
      metric_group.save

      plugin.tags.each do |tag_name|
        tag = @tags.detect { |t| t.name == tag_name }
        if tag.nil?
          log(Logger::INFO, "Creating tag `#{tag_name}`")
          tag = ::Copperegg::Revealmetrics::Tag.new(name: tag_name)
        end
        object_identifier = plugin.source_identifier
        unless tag.objects.include?(object_identifier)
          log(Logger::INFO, "Attaching object to tag `#{tag_name}`")
          tag.objects << object_identifier
          store_sample(plugin, Time.now, {}) # Need to store a sample before we can tag a custom object
        end
        log(Logger::INFO, "Updating tag `#{tag_name}`")
        tag.save
      end

      dashboard = @dashboards.detect { |d| d.name == plugin.metric_group }
      if dashboard.nil?
        log(Logger::INFO, "Creating dashboard `#{plugin.metric_group}`")
        metrics = metric_group.metrics || []
        ::Copperegg::Revealmetrics::CustomDashboard.create(metric_group, name: plugin.metric_group, identifiers: nil, metrics: metrics)
      end
    end

    def store_sample(plugin, time, data)
      response = ::Copperegg::Revealmetrics::MetricSample.save(plugin.metric_group, plugin.source_identifier, time.to_i, data)
      if response.code != '200'
        raise("Cannot store copperegg data `#{data}`. Response code `#{response.code}`, message `#{response.message}`, body `#{response.body}`")
      end
    end

    def _load_metric_groups
      log(Logger::INFO, 'Loading metric groups')
      metric_groups = ::Copperegg::Revealmetrics::MetricGroup.find
      raise 'Cannot load metric groups' if metric_groups.nil?
      metric_groups
    end

    def _load_dashboards
      log(Logger::INFO, 'Loading dashboards')
      dashboards = ::Copperegg::Revealmetrics::CustomDashboard.find
      raise 'Cannot load dashboards' if dashboards.nil?
      dashboards
    end

    # @return [Copperegg::Revealmetrics::Tag[]]
    def _load_tags
      log(Logger::INFO, 'Loading tags')
      tags = ::Copperegg::Revealmetrics::Tag.find
      raise 'Cannot load tags' if tags.nil?
      tags
    end
  end
end
