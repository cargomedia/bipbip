require 'mysql2'

module Bipbip

  class Plugin::Mysql < Plugin

    def metrics_schema
      [
          {:name => 'Max_used_connections', :type => 'gauge', :unit => 'Connections'},
          {:name => 'Connections', :type => 'counter', :unit => 'Connections'},
          {:name => 'Threads_connected', :type => 'gauge', :unit => 'Threads'},

          {:name => 'Seconds_Behind_Master', :type => 'gauge', :unit => 'Seconds'},

          {:name => 'Created_tmp_disk_tables', :type => 'counter', :unit => 'Tables'},

          {:name => 'Queries', :type => 'counter', :unit => 'Queries'},
          {:name => 'Slow_queries', :type => 'counter', :unit => 'Queries'},

          {:name => 'Table_locks_immediate', :type => 'counter', :unit => 'Locks'},
          {:name => 'Table_locks_waited', :type => 'counter', :unit => 'Locks'},

          {:name => 'Processlist', :type => 'gauge', :unit => 'Processes'},
          {:name => 'Processlist_Locked', :type => 'gauge', :unit => 'Processes'},

          {:name => 'Com_select', :type => 'counter', :unit => 'Commands'},
          {:name => 'Com_delete', :type => 'counter', :unit => 'Commands'},
          {:name => 'Com_insert', :type => 'counter', :unit => 'Commands'},
          {:name => 'Com_update', :type => 'counter', :unit => 'Commands'},
          {:name => 'Com_replace', :type => 'counter', :unit => 'Commands'},
      ]
    end

    def monitor
      mysql = Mysql2::Client.new(
          :host => config['hostname'],
          :port => config['port'],
          :username => config['username'],
          :password => config['password']
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

      mysql.close

      data = {}
      metrics_names.each do |key|
        data[key] = stats[key]
      end
      data
    end
  end
end
