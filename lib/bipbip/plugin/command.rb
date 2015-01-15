require 'open3'
require 'json'

module Bipbip

  class Plugin::Command < Plugin

    attr_accessor :schema

    def metrics_schema
      @schema ||= find_schema
    end

    def monitor
      Hash[command_output.map { |metric, value| [metric, metric_value(value)] }]
    end

    def source_identifier
      Bipbip.fqdn + '::' + @metric_group + '::' + config.values.first.to_s.gsub(/[^\w]/, '_')[0..20]
    end

    private

    def metric_value(value)
      value = value['value'] if detect_operation_mode(value) == :advanced
      value = 1 if value == 'true' or value == true
      value = 0 if value == 'false' or value == false
      value
    end

    def find_schema
      command_output.map do |metric, value|
        case detect_operation_mode(value)
          when :simple
            {:name => "#{metric}", :type => 'gauge'}
          when :advanced
            {:name => "#{metric}", :type => value['type'], :unit => value['unit']}
        end
      end
    end

    def detect_operation_mode(value)
      {true => :advanced, false => :simple}.fetch(value.is_a?(Hash))
    end

    def command_output
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
