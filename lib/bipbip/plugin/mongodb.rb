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
          {:name => 'slow_queries_count', :type => 'gauge_f', :unit => 'Queries'},
          {:name => 'slow_queries_time_avg', :type => 'gauge_f', :unit => 'Seconds'},
          {:name => 'slow_queries_time_max', :type => 'gauge_f', :unit => 'Seconds'},
      ]
    end

    def monitor
      @mongodb_client = nil

      status = fetch_server_status
      slow_queries_status = fetch_slow_queries_status

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

      data['slow_queries_count'] = slow_queries_status['total']['count']
      data['slow_queries_time_avg'] = slow_queries_status['total']['count'] > 0 ? (slow_queries_status['total']['time'].to_f/slow_queries_status['total']['count'].to_f) : 0
      data['slow_queries_time_max'] = slow_queries_status['max']['time']

      data
    end

    private

    def slow_query_threshold
      config['slow_query_threshold'] || 0
    end

    # @return [Mongo::Client]
    def mongodb_client
      options = {
          'hostname' => 'localhost',
          'port' => 27017,
      }.merge(config)
      @mongodb_client ||= Mongo::Client.new([options['hostname'] + ':' + options['port'].to_s], :socket_timeout => 2)
    end

    # @return [Mongo::DB]
    def mongodb_database(db_name)
      mongodb_client.with(config['username'], config['password']) unless config['password'].nil?
      mongodb_client.use(db_name)
    end

    def fetch_server_status
      mongodb_database('admin').command('serverStatus' => 1).documents.first
    end

    def fetch_replica_status
      mongodb_database('admin').command('replSetGetStatus' => 1).documents.first
    end

    def slow_query_last_check
      old = (@slow_query_last_check || Time.now)
      @slow_query_last_check = Time.now
      old
    end

    def fetch_slow_queries_status
      timestamp_last_check = slow_query_last_check
      time_period = Time.now - timestamp_last_check

      database_names_ignore = ['admin', 'system', 'local']
      database_list = (mongodb_client.database_names - database_names_ignore).map { |name| mongodb_database(name) }

      stats = database_list.reduce({'total' => {'count' => 0, 'time' => 0}, 'max' => {'time' => 0}}) do |memo, database|

        results = database['system.profile'].find.aggregate(
            [
                {'$match' => {'millis' => {'$gte' => slow_query_threshold}, 'ts' => {'$gt' => timestamp_last_check}}},
                {'$group' => {'_id' => 'null', 'total_count' => {'$sum' => 1}, 'total_time' => {'$sum' => '$millis'}, 'max_time' => {'$max' => '$millis'}}}
            ])

        unless results.count == 0
          result = results.first
          max_time = result['max_time'].to_f/1000

          memo['total']['count'] += result['total_count']
          memo['total']['time'] += result['total_time'].to_f/1000
          memo['max']['time'] = max_time if memo['max']['time'] < max_time
        end

        memo
      end

      stats['total'].each { |metric, value| stats['total'][metric] = value/time_period }

      stats
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
