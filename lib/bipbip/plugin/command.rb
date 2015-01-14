require 'open3'
require 'json'

module Bipbip

  class Plugin::Command < Plugin

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
      command = config['command'].to_s
      env = {}

      output_stdout = output_stderr = exit_code = nil
      Open3.popen3(ENV.to_hash.merge(env), command) { |stdin, stdout, stderr, wait_thr|
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
