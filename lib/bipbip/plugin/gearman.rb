require 'gearman/server'
class GearmanServer < Gearman::Server
end

module Bipbip
  class Plugin::Gearman < Plugin
    def metrics_schema
      [
        { name: 'jobs_queued_total', type: 'gauge', unit: 'Jobs' },
        { name: 'jobs_active_total', type: 'gauge', unit: 'Jobs' },
        { name: 'jobs_waiting_total', type: 'gauge', unit: 'Jobs' }
      ]
    end

    def monitor
      gearman = GearmanServer.new(config['hostname'] + ':' + config['port'].to_s)
      stats = gearman.status

      jobs_queued_total = 0
      jobs_active_total = 0
      stats.each do |_function_name, data|
        jobs_queued_total += data[:queue].to_i
        jobs_active_total += data[:active].to_i
        jobs_waiting_total += (jobs_queued_total - jobs_active_total)
      end

      {
        jobs_queued_total: jobs_queued_total,
        jobs_active_total: jobs_active_total,
        jobs_waiting_total: jobs_waiting_total
      }
    end
  end
end
