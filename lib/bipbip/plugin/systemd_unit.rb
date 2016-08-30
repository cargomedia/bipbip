# encoding: utf-8

require 'komenda'

module Bipbip
  class Plugin::SystemdUnit < Plugin
    def metrics_schema
      [
        { name: 'all_units_running', type: 'gauge', unit: 'Boolean' }
      ]
    end

    def monitor
      main_unit = config['unit_name']
      { 'all_units_running' => unit_dependencies(main_unit).all? { |unit| unit_is_active(unit) } ? 1 : 0 }
    end

    # @param [String] main_unit
    # @return [Array<String>]
    def unit_dependencies(main_unit)
      result = Komenda.run(['systemctl', 'list-dependencies', '--plain', '--full', main_unit], fail_on_fail: true)
      result.stdout.lines.map do |line|
        line.strip.gsub(/^● /, '')
      end
    end

    # @param [String] unit
    # @return [TrueClass, FalseClass]
    def unit_is_active(unit)
      Komenda.run(['systemctl', 'is-active', unit]).success?
    end
  end
end
