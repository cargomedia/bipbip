require 'mysql2'

module CoppereggAgents

  class Plugin::Mysql < Plugin

    def metrics_schema
      [
          {:name => 'Threads_connected', :type => 'ce_gauge', :unit => 'Threads'},
          {:name => 'Created_tmp_disk_tables', :type => 'ce_counter', :unit => 'Tables'},
          {:name => 'Qcache_hits', :type => 'ce_counter', :unit => 'Hits'},
          {:name => 'Queries', :type => 'ce_counter', :unit => 'Queries'},
          {:name => 'Slow_queries', :type => 'ce_counter', :unit => 'Queries'},
          {:name => 'Bytes_received', :type => 'ce_counter', :unit => 'Bytes'},
          {:name => 'Bytes_sent', :type => 'ce_counter', :unit => 'Bytes'},
          {:name => 'Com_insert', :type => 'ce_counter', :unit => 'Commands'},
          {:name => 'Com_select', :type => 'ce_counter', :unit => 'Commands'},
          {:name => 'Com_update', :type => 'ce_counter', :unit => 'Commands'},
      ]
    end

    def monitor(server)
      mysql = Mysql2::Client.new(
          :host => server['hostname'],
          :port => server['port'],
          :username => server['username'],
          :password => server['password'],
      )
      stats = mysql.query('SHOW GLOBAL STATUS;')

      keys = [
          :Threads_connected,
          :Created_tmp_disk_tables,
          :Qcache_hits,
          :Queries,
          :Slow_queries,
      ]

      data = {}
      stats.each do |row|
        p row
        data[row['Variable_name']] = row['Value'].to_i
      end
      data
    end
  end
end
