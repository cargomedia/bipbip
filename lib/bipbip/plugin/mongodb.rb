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
          {:name => 'mem_pagefaults', :type => 'gauge', :unit => 'faults'},
          {:name => 'globalLock_currentQueue', :type => 'gauge'},
      ]
    end

    def monitor
      options = {
          'hostname' => 'localhost',
          'port' => 27017,
          'username' => nil,
          'password' => nil
      }.merge(config)
      connection = Mongo::MongoClient.new(options['hostname'], options['port'], {:op_timeout => 2, :slave_ok => true})
      mongo = connection.db('admin')
      mongo.authenticate(options['username'], options['password']) unless options['password'].nil?
      mongoStats = mongo.command('serverStatus' => 1)

      data = {}

      if mongoStats['indexCounters']
        data.merge!({'btree_misses' => mongoStats['indexCounters']['misses'].to_i})
      end
      if mongoStats['backgroundFlushing']
        data.merge!({'flushing_last_ms' => mongoStats['backgroundFlushing']['last_ms'].to_i})
      end
      if mongoStats['opcounters']
        data.merge!({
                        'op_inserts' => mongoStats['opcounters']['insert'].to_i,
                        'op_queries' => mongoStats['opcounters']['query'].to_i,
                        'op_updates' => mongoStats['opcounters']['update'].to_i,
                        'op_deletes' => mongoStats['opcounters']['delete'].to_i,
                        'op_getmores' => mongoStats['opcounters']['getmore'].to_i,
                        'op_commands' => mongoStats['opcounters']['command'].to_i,

                    })
      end
      if mongoStats['connections']
        data.merge!({'connections_current' => mongoStats['connections']['current'].to_i})
      end
      if mongoStats['mem']
        data.merge!({
                        'mem_resident' => mongoStats['mem']['resident'].to_i,
                        'mem_mapped' => mongoStats['mem']['mapped'].to_i,
                    })
      end
      if mongoStats['extra_info']
        data.merge!({'mem_pagefaults' => mongoStats['extra_info']['page_faults'].to_i, })
      end
      if mongoStats['globalLock']
        data.merge!({
                        'globalLock_currentQueue' => mongoStats['globalLock']['currentQueue']['total'].to_i
                    }) if mongoStats['globalLock']['currentQueue']
      end

    end
  end
end
