require 'open3'
require 'json'

module Bipbip
  class Plugin::CommandStatus < Plugin
    def metrics_schema
      [
        { name: 'status', type: 'gauge', unit: '' }
      ]
    end

    def monitor
      command = config['command'].to_s
      output_stdout = output_stderr = exit_code = nil
      Open3.popen3(command) do |_stdin, stdout, stderr, wait_thr|
        output_stdout = stdout.read.chomp
        output_stderr = stderr.read.chomp
        exit_code = wait_thr.value
      end

      puts output_stdout unless output_stdout.empty?
      puts output_stderr unless output_stderr.empty?
      {
        status: exit_code.exitstatus
      }
    end
  end
end
