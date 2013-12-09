require 'gearman/server'
class GearmanServer < Gearman::Server
end

module CoppereggAgents

  class Plugin::Gearman < Plugin

    def metrics_schema
      [
          {:name => 'jobs_queued_total', :type => 'ce_gauge', :unit => 'Jobs'},
      ]
    end

    def monitor(server)
      gearman = GearmanServer.new(server['hostname'] + ':' + server['port'].to_s)
      stats = gearman.status

      pre_data = {:jobs_queued_total => 0}
      stats.each do |function_name, data|
        data.each do |queue, stats|
          pre_data[:jobs_queued_total] += queue.to_i
        end
      end

      data = {}
      metrics_names.each do |key|
        data[key] = pre_data[key.to_sym].to_i
      end
      data
    end
  end
end
