require 'redis'
require 'resque'


module Bipbip

  class Plugin::Resque < Plugin

    def metrics_schema
      schema_list = [
          {:name => 'num_workers', :type => 'counter', :unit => 'Workers'},
          {:name => 'num_idle_workers', :type => 'counter', :unit => 'Workers'},
          {:name => 'num_active_workers', :type => 'counter', :unit => 'Workers'},
      ]
      
      with_resque_connection do 
        ::Resque.queues.each do |queue|
          schema_list << {:name => "queue_size_#{sanitize_queue_name(queue)}", :type => 'gauge', :unit => 'Jobs' }
        end
      end

      schema_list
    end

    def sanitize_queue_name(queue)
      queue.gsub(/\s/,'-')
    end

    def with_resque_connection
      redis = ::Redis.new(
          :host => config['hostname'] || 'localhost',
          :port => config['port'] || 6369
      )
      redis.select config['database']
      ::Resque.redis = redis
      ::Resque.redis.namespace = config['namespace'] unless config['namespace'].nil?

      yield

      redis.quit
    end

    def monitor
      data = {}
      with_resque_connection do
        data['num_workers'] = ::Resque.workers.count
        data['num_idle_workers'] = ::Resque.workers.select {|w| w.idle? }.count
        data['num_active_workers'] = data['num_workers'] - data['num_idle_workers']
        ::Resque.queues.each do |queue|
          data["queue_size_#{sanitize_queue_name(queue)}"] = ::Resque.size(queue).to_i
        end
      end      
      data
    end
  end
end
