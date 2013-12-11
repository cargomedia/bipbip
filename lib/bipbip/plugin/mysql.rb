require 'mysql2'

module Bipbip

  class Plugin::Mysql < Plugin

    def metrics_schema
      [
          {:name => 'max_connections', :type => 'ce_gauge', :unit => 'Connections'},
          {:name => 'Max_used_connections', :type => 'ce_gauge', :unit => 'Connections'},
          {:name => 'Connections', :type => 'ce_counter', :unit => 'Connections'},
          {:name => 'Threads_connected', :type => 'ce_gauge', :unit => 'Threads'},

          {:name => 'Seconds_Behind_Master', :type => 'ce_gauge', :unit => 'Seconds'},

          {:name => 'Created_tmp_disk_tables', :type => 'ce_counter', :unit => 'Tables'},

          {:name => 'Queries', :type => 'ce_counter', :unit => 'Queries'},
          {:name => 'Slow_queries', :type => 'ce_counter', :unit => 'Queries'},

          {:name => 'Bytes_received', :type => 'ce_counter', :unit => 'b'},
          {:name => 'Bytes_sent', :type => 'ce_counter', :unit => 'b'},

          {:name => 'Table_locks_immediate', :type => 'ce_counter', :unit => 'Locks'},
          {:name => 'Table_locks_waited', :type => 'ce_counter', :unit => 'Locks'},

          {:name => 'Processlist', :type => 'ce_gauge', :unit => 'Processes'},
          {:name => 'Processlist_Locked', :type => 'ce_gauge', :unit => 'Processes'},
          {:name => 'Processlist_Sending_data', :type => 'ce_gauge', :unit => 'Processes'},

          {:name => 'Com_select', :type => 'ce_counter', :unit => 'Commands'},
          {:name => 'Com_delete', :type => 'ce_counter', :unit => 'Commands'},
          {:name => 'Com_insert', :type => 'ce_counter', :unit => 'Commands'},
          {:name => 'Com_update', :type => 'ce_counter', :unit => 'Commands'},
          {:name => 'Com_replace', :type => 'ce_counter', :unit => 'Commands'},
      ]
    end

    def monitor(server)
      mysql = Mysql2::Client.new(
          :host => server['hostname'],
          :port => server['port'],
          :username => server['username'],
          :password => server['password']
      )

      stats = Hash.new(0)

      mysql.query('SHOW GLOBAL STATUS').each do |v|
        stats[v['Variable_name']] = v['Value'].to_i
      end

      mysql.query('SHOW VARIABLES').each do |v|
        stats[v['Variable_name']] = v['Value'].to_i
      end

      slave_status = mysql.query('SHOW SLAVE STATUS').first
      if slave_status
        stats['Seconds_Behind_Master'] = slave_status['Seconds_Behind_Master'].to_i
      end

      processlist =  mysql.query('SHOW PROCESSLIST')
      stats['Processlist'] = processlist.count
      processlist.each do |process|
        state = process['State'].to_s
        stats['Processlist_' + state.sub(' ', '_')] += 1 unless state.empty?
      end

      data = {}
      metrics_names.each do |key|
        data[key] = stats[key]
      end
      data
    end
  end
end
