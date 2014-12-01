module Bipbip

  class Plugin::Postfix < Plugin

    def metrics_schema
      [
          {:name => 'mails_queued_total', :type => 'gauge', :unit => 'Mails'},
      ]
    end

    def monitor
      queue_counter = /(\d+) Request+s?\.$/.match(postqueue)
      {
          'mails_queued_total' => queue_counter.nil? ? 0 : queue_counter[1].to_i
      }
    end

    private

    def postqueue(args = '-p')
      `postqueue #{args}`
    end
  end
end
