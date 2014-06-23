require 'monit'

module Bipbip

  class Plugin::Monit < Plugin

    def metrics_schema
      [
          {:name => 'Running', :type => 'gauge', :unit => 'Boolean'},
          {:name => 'All_Services_ok', :type => 'gauge', :unit => 'Boolean'},
      ]
    end

    def monitor
      status =  ::Monit::Status.new({
        :host => 'localhost',
        :port => 2812,
        :ssl => false,
        :auth => false,
        :username => nil,
        :password => nil,
      }.merge(config))

      data = Hash.new(0)

      begin
        data['Running'] = status.get ? 1 : 0
        data['All_Services_ok'] = status.services.any? { |service| service.monitor != '1' || service.status != '0' } ? 0 : 1
      rescue
        data['Running'] = 0
        data['All_Services_ok'] = 0
      end
      data
    end
  end
end
