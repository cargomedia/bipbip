require 'mysql2'
require 'monit'
class MonitStatus < Monit::Status

end

module Bipbip

  class Plugin::Monit < Plugin

    def metrics_schema
      [
          {:name => 'Running', :type => 'gauge', :unit => 'Boolean'},
          {:name => 'All_Services_ok', :type => 'gauge', :unit => 'Boolean'},
      ]
    end

    def monitor
      status =  MonitStatus.new(
          :host => config['host'],
          :auth => config['auth']
      )
      value = Hash.new(0)

      begin
        value['Running'] = status.get
      rescue
        value['Running'] = false
        value['All_Services_ok'] = false
      end

      if value['Running']
        value['All_Services_ok'] = true
        status.services.each do |service|
          if service.monitor != 1 || service.status != 0
            value['All_Services_ok'] = false
            break
          end
        end
      end

      data = {}
      metrics_schema.each do |metric|
        name = metric[:name]
        data[name] = value[name]? 1 : 0
      end
      data
    end
  end
end
