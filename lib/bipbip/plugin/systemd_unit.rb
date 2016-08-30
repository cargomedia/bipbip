# encoding: utf-8

require 'open3'
require 'komenda'

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
      data['all_units_running'] = unit_dependencies(main_unit).all? { |unit| unit_is_active(unit) }
      data
    end

    # @param [String] main_unit
    # @return [Array<String>]
    def unit_dependencies(main_unit)
      Komenda.run(['systemctl','list-dependencies', '--plain', '--full', main_unit]).stdout.split("\n").map do |line|
        line.gsub(/^● /, '')
      end
    end

    # @param [String] unit
    # @return [TrueClass, FalseClass]
    def unit_is_active(unit)
      Komenda.run(['systemctl','is-active', unit]).success?
    end
  end
end
