require 'json'
require 'vine'

module Bipbip

  class Plugin::Mongodb < Plugin

    def metrics_schema
      [
        {:name => 'Inserts', :keyname => 'opcounters.insert', :type => 'counter'},
        {:name => 'Queries', :keyname => 'opcounters.query', :type => 'counter'},
        {:name => 'Updates', :keyname => 'opcounters.update', :type => 'counter'},
        {:name => 'Deletes', :keyname => 'opcounters.delete', :type => 'counter'},
        {:name => 'Getmores', :keyname => 'opcounters.getmore', :type => 'counter'},
        {:name => 'Commands', :keyname => 'opcounters.command', :type => 'counter'},
        {:name => 'Flushes', :keyname => 'backgroundFlushing.flushes', :type => 'counter'},
        {:name => 'FlushTotal', :keyname => 'backgroundFlushing.total_ms', :type => 'gauge', :unit => 'ms'},
        {:name => 'FlushAvg', :keyname => 'backgroundFlushing.average_ms', :type => 'gauge', :unit => 'ms'},
        {:name => 'FlushLast', :keyname => 'backgroundFlushing.last_ms', :type => 'gauge', :unit => 'ms'},
        {:name => 'Mapped', :keyname => 'mem.mapped', :type => 'gauge', :unit => 'MB'},
        {:name => 'Vsize', :keyname => 'mem.virtual', :type => 'gauge', :unit => 'MB'},
        {:name => 'Rsize', :keyname => 'mem.resident', :type => 'gauge', :unit => 'MB'},
        {:name => 'PageFaults', :keyname => 'extra_info.page_faults', :type => 'gauge'},
        {:name => 'IndexMiss', :keyname => 'indexCounters.missRatio', :type => 'counter', :unit => '%'},
        {:name => 'IndexAccess', :keyname => 'indexCounters.accesses', :type => 'counter'},
        {:name => 'IndexHits', :keyname => 'indexCounters.hits', :type => 'counter'},
        {:name => 'IndexResets', :keyname => 'indexCounters.resets', :type => 'counter'},
        {:name => 'TrafficIn', :keyname => 'network.bytesIn', :type => 'gauge', :unit => 'b'},
        {:name => 'TrafficOut', :keyname => 'network.bytesOut', :type => 'gauge', :unit => 'b'},
        {:name => 'Connections', :keyname => 'connections.current', :type => 'gauge'},
      ]
    end

    def monitor
      arguments = ['port', 'host', 'username', 'password']
      mongo_options = ['--quiet']
      arguments.each do |arg|
        mongo_options << ["--#{arg}", config[arg]] if config.has_key?(arg)
      end
      response = `2>&1 mongo --eval 'printjson(db.serverStatus())' #{mongo_options.join(' ')}`

      # Sanitize JSON
      # sed -E 's/NumberLong\("?([0-9]+)"?\)/\1/' output
      # sed -E 's/ISODate\((".+Z")\)/\1/' output
      sanitized_response = response.gsub /NumberLong\("?([0-9]+)"?\)/, '\1'
      sanitized_response = sanitized_response.gsub /ISODate\((".+Z")\)/, '\1'

      status = JSON.parse(sanitized_response)

      data = {}
      metrics_schema.each do |metric|
        name = metric[:name]
        unit = metric[:unit]
        data[name] = status.access(metric[:keyname])
      end
      data
    end
  end
end
