require 'open3'

module Bipbip
  class Plugin::SystemdUnit < Plugin
    def metrics_schema
      [
        { name: 'all_units_running', type: 'gauge', unit: 'Boolean' }
      ]
    end

    def monitor
      data = Hash.new(0)
      main_unit = config['unit_name']
      data['all_units_running'] = units(main_unit).all? { |unit| unit_is_running(unit) }
      data
    end

    # @param [String] main_unit
    # @return [Array<String>]
    def units(main_unit)
      command = "for unit in $(systemctl list-dependencies --plain --full #{main_unit}); do if [ \"${unit}\" != \"●\" ]; then echo \"${unit}\"; fi; done"
      exec_command(command).split("\n")
    end

    # @param [String] unit
    # @return [TrueClass, FalseClass]
    def unit_is_running(unit)
      exec_command("systemctl is-active --quiet #{unit}; echo $?").to_i == 0
    end

    def exec_command(command)
      output_stdout = output_stderr = exit_code = nil
      Open3.popen3(command) do |_stdin, stdout, stderr, wait_thr|
        output_stdout = stdout.read.chomp
        output_stderr = stderr.read.chomp
        exit_code = wait_thr.value
      end

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
