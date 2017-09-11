# encoding: utf-8

require 'komenda'

module Bipbip
  class Plugin::SystemdUnit < Plugin
    def metrics_schema
      [
        { name: 'all_units_active', type: 'gauge', unit: 'Boolean' },
        { name: 'any_unit_failed', type: 'gauge', unit: 'Boolean' },
        { name: 'any_unit_stopped', type: 'gauge', unit: 'Boolean' }
      ]
    end

    def monitor
      main_unit = config['unit_name']
      failed_units = []
      stopped_units = []
      status_list = unit_dependencies(main_unit).map do |unit|

        is_active = unit_is_active(unit)
        is_failed = unit_is_failed(unit)
        is_stopped = !is_active && !is_failed

        failed_units.push(unit) if is_failed
        stopped_units.push(unit) if is_stopped
        {
          name: unit,
          is_active: is_active,
          is_failed: is_failed,
          is_stopped: is_stopped
        }
      end

      log(Logger::WARN, "#{main_unit} unit failed: #{failed_units.join(', ')}") unless failed_units.empty?
      log(Logger::WARN, "#{main_unit} unit stopped: #{stopped_units.join(', ')}") unless stopped_units.empty?

      {
        'all_units_active' => (status_list.all? { |status| status[:is_active] } ? 1 : 0),
        'any_unit_failed' => (status_list.any? { |status| status[:is_failed] } ? 1 : 0),
        'any_unit_stopped' => (status_list.any? { |status| status[:is_stopped] } ? 1 : 0)
      }
    end

    # @param [String] main_unit
    # @return [Array<String>]
    def unit_dependencies(main_unit)
      result = Komenda.run(['systemctl', 'list-dependencies', '--plain', '--full', main_unit], fail_on_fail: true)
      result.stdout.force_encoding('utf-8').lines.map do |line|
        line.strip.gsub(/^[●*]\s+/, '')
      end
    end

    # @param [String] unit
    # @return [TrueClass, FalseClass]
    def unit_is_active(unit)
      Komenda.run(['systemctl', 'is-active', unit]).success?
    end

    # @param [String] unit
    # @return [TrueClass, FalseClass]
    def unit_is_failed(unit)
      Komenda.run(['systemctl', 'is-failed', unit]).success?
    end
  end
end
