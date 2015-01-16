require 'mongo'

module Bipbip

  class Plugin::Mongodb < Plugin

    def metrics_schema
      [
          {:name => 'flushing_last_ms', :type => 'gauge', :unit => 'ms'},
          {:name => 'btree_misses', :type => 'gauge', :unit => 'misses'},
          {:name => 'op_inserts', :type => 'counter'},
          {:name => 'op_queries', :type => 'counter'},
          {:name => 'op_updates', :type => 'counter'},
          {:name => 'op_deletes', :type => 'counter'},
          {:name => 'op_getmores', :type => 'counter'},
          {:name => 'op_commands', :type => 'counter'},
          {:name => 'connections_current', :type => 'gauge'},
          {:name => 'mem_resident', :type => 'gauge', :unit => 'MB'},
          {:name => 'mem_mapped', :type => 'gauge', :unit => 'MB'},
          {:name => 'mem_pagefaults', :type => 'counter', :unit => 'faults'},
          {:name => 'globalLock_currentQueue', :type => 'gauge'},
          {:name => 'replication_lag', :type => 'gauge', :unit => 'Seconds'},
      ]
    end

    def monitor
      @mongodb_connection = nil

      status = fetch_server_status

      data = {}

      if status['indexCounters']
        data['btree_misses'] = status['indexCounters']['misses'].to_i
      end
      if status['backgroundFlushing']
        data['flushing_last_ms'] = status['backgroundFlushing']['last_ms'].to_i
      end
      if status['opcounters']
        data['op_inserts'] = status['opcounters']['insert'].to_i
        data['op_queries'] = status['opcounters']['query'].to_i
        data['op_updates'] = status['opcounters']['update'].to_i
        data['op_deletes'] = status['opcounters']['delete'].to_i
        data['op_getmores'] = status['opcounters']['getmore'].to_i
        data['op_commands'] = status['opcounters']['command'].to_i
      end
      if status['connections']
        data['connections_current'] = status['connections']['current'].to_i
      end
      if status['mem']
        data['mem_resident'] = status['mem']['resident'].to_i
        data['mem_mapped'] = status['mem']['mapped'].to_i
      end
      if status['extra_info']
        data['mem_pagefaults'] = status['extra_info']['page_faults'].to_i
      end
      if status['globalLock'] && status['globalLock']['currentQueue']
        data['globalLock_currentQueue'] = status['globalLock']['currentQueue']['total'].to_i
      end
      if status['repl'] && status['repl']['secondary'] == true
        data['replication_lag'] = replication_lag
      end
      data
    end

    private

    def mongodb_database(db_name)
      options = {
          'hostname' => 'localhost',
          'port' => 27017,
          'username' => nil,
          'password' => nil
      }.merge(config)

      @mongodb_connection ||= Mongo::MongoClient.new(options['hostname'], options['port'], {:op_timeout => 2, :slave_ok => true})

      db = @mongodb_connection.db(db_name)
      db.authenticate(options['username'], options['password']) unless options['password'].nil?
      db
    end

    def fetch_server_status
      mongodb_database('admin').command('serverStatus' => 1)
    end

    def fetch_replica_status
      mongodb_database('admin').command('replSetGetStatus' => 1)
    end

    def replication_lag
      status = fetch_replica_status
      member_list = status['members']
      primary = member_list.select { |member| member['stateStr'] == 'PRIMARY' }.first
      secondary = member_list.select { |member| member['stateStr'] == 'SECONDARY' and member['self'] == true }.first

      raise "No primary member in replica `#{status['set']}`" if primary.nil?
      raise "Cannot find itself as secondary member in replica `#{status['set']}`" if secondary.nil?

      (secondary['optime'].seconds - primary['optime'].seconds)
    end
  end
end
