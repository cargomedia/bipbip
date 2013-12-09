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
      stats = Hash[stats.map {|v| [v['Variable_name'], v['Value']]}]

      data = {}
      metrics_names.each do |key|
        data[key] = stats[key.to_sym].to_i
      end
      data
    end
  end
end
