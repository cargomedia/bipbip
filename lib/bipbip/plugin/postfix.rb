module Bipbip

  class Plugin::Postfix < Plugin

    def metrics_schema
      [
          {:name => 'mails_queued_total', :type => 'gauge', :unit => 'Mails'},
      ]
    end

    def monitor
      queue_counter = /^-- (.*) in (\d+) Requests.$/.match(postqueue)
      {
          'mails_queued_total' => queue_counter[2].to_i
      }
    end

    private

    def postqueue(args = '-p')
      `postqueue #{args}`
    end
  end
end
