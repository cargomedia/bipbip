require 'open3'
require 'json'

module Bipbip

  class Plugin::Command < Plugin

    attr_accessor :schema

    def metrics_schema
      @schema ||= find_schema
    end

    def monitor
      Hash[data.map { |k, v| [k, metric_value(v)] }]
    end

    private

    def metric_value(v)
      v = v['value'] if config['mode'] == 'advanced'
      v = 1 if v == 'true' or v == true
      v = 0 if v == 'false' or v == false
      v
    end

    def find_schema
      metrics = []
      data.each do |metric, value|
        case config['mode']
          when 'simple'
            metrics.push({:name => "#{metric}", :type => 'gauge'})
          when 'advanced'
            metrics.push({:name => "#{metric}", :type => value['type'], :unit => value['unit']})
        end
      end

      metrics
    end

    def data
      JSON.parse(exec_command)
    end

    def exec_command
      command = config['command'].to_s

      output_stdout = output_stderr = exit_code = nil
      Open3.popen3(command) { |stdin, stdout, stderr, wait_thr|
        output_stdout = stdout.read.chomp
        output_stderr = stderr.read.chomp
        exit_code = wait_thr.value
      }

      unless exit_code.success?
        message = ['Command execution failed:', command]
        message.push 'STDOUT:', output_stdout unless output_stdout.empty?
        message.push 'STDERR:', output_stderr unless output_stderr.empty?
        raise message.join("\n")
      end

      output_stdout
    end

  end
end
