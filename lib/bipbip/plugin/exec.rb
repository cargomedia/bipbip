require 'json'
module Bipbip

  class Plugin::Exec < Plugin

    attr_accessor :schema

    def metrics_schema
      @schema ||= find_schema
    end

    def monitor
      Hash[data.map { |k, v| [k, (v ? 1 : 0)] }]
    end

    private

    def find_schema
      metrics = []
      data.each do |metric, value|
        type = config['type'].to_s
        unit = config['unit'].to_s
        metrics.push({:name => "#{metric}", :type => type, :unit => unit})
      end
      metrics
    end

    def data
      JSON.parse(exec_command)
    end

    def exec_command
      `#{config['command'].to_s}`
    end

  end
end
