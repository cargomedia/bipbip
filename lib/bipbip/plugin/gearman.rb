require 'gearman/server'
require 'mysql2'
class GearmanServer < Gearman::Server
end

module Bipbip
  class Plugin::Gearman < Plugin
    JOB_PRIORITY_HIGH = 0
    JOB_PRIORITY_NORMAL = 1
    JOB_PRIORITY_LOW = 2

    def metrics_schema
      [
        { name: 'jobs_queued_total', type: 'gauge', unit: 'Jobs' },
        { name: 'jobs_active_total', type: 'gauge', unit: 'Jobs' },
        { name: 'jobs_waiting_total', type: 'gauge', unit: 'Jobs' },

        { name: 'jobs_queued_total_low', type: 'gauge', unit: 'Jobs' },
        { name: 'jobs_queued_total_normal', type: 'gauge', unit: 'Jobs' },
        { name: 'jobs_queued_total_high', type: 'gauge', unit: 'Jobs' }
      ]
    end

    def monitor
      stats = _fetch_gearman_status

      jobs_queued_total = 0
      jobs_active_total = 0
      stats.each do |_function_name, data|
        jobs_queued_total += data[:queue].to_i
        jobs_active_total += data[:active].to_i
      end

      priority_stats = {}
      if config['persistence'] == 'mysql'
        stats = _fetch_mysql_priority_stats(config)
        priority_stats = {
          jobs_queued_total_high: stats[JOB_PRIORITY_HIGH],
          jobs_queued_total_normal: stats[JOB_PRIORITY_NORMAL],
          jobs_queued_total_low: stats[JOB_PRIORITY_LOW]
        }
      end

      {
        jobs_queued_total: jobs_queued_total,
        jobs_active_total: jobs_active_total,
        jobs_waiting_total: (jobs_queued_total - jobs_active_total)
      }.merge(priority_stats)
    end

    private

    def _fetch_gearman_status
      gearman = GearmanServer.new(config['hostname'] + ':' + config['port'].to_s)
      gearman.status
    end

    def _fetch_mysql_priority_stats(config)
      mysql = Mysql2::Client.new(
        host: config['mysql_hostname'] || 'localhost',
        port: config['mysql_port'] || 3306,
        username: config['mysql_username'] || nil,
        password: config['mysql_password'] || nil,
        database: config['mysql_database'] || 'gearman'
      )

      stats = Hash.new(0)

      mysql_table = config['mysql_table'] || 'gearman_queue'
      mysql.query("SELECT priority, count(priority) as jobs_count FROM #{mysql_table} GROUP by priority").each do |row|
        stats[row['priority']] = row['jobs_count']
      end

      stats
    end
  end
end
