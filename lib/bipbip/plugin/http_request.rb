require 'json'

module Bipbip
  class Plugin::HttpRequest < Plugin
    attr_accessor :schema

    def metrics_schema
      @schema ||= find_schema
    end

    def monitor
      Hash[request.map { |metric, value| [metric, metric_value(value)] }]
    end

    def request
      uri = URI.parse(config['url'])
      response = Net::HTTP.get_response(uri)
      raise "Invalid response from server at #{config['url']}" unless response.code == '200'
      JSON.parse(response.body)
    end

    private

    def metric_value(value)
      value = value['value'] if detect_operation_mode(value) == :advanced
      value = 1 if value == 'true' || value == true
      value = 0 if value == 'false' || value == false
      value
    end

    def find_schema
      request.map do |metric, value|
        case detect_operation_mode(value)
        when :simple
          { name: metric.to_s, type: 'gauge' }
        when :advanced
          { name: metric.to_s, type: value['type'], unit: value['unit'] }
        end
      end
    end

    def detect_operation_mode(value)
      { true => :advanced, false => :simple }.fetch(value.is_a?(Hash))
    end
  end
end
