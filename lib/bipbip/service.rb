module Bipbip

  class Service

    attr_accessor :plugin
    attr_accessor :config

    def initialize(plugin, config)
      @plugin = plugin
      @config = config.to_h
    end

    def run
      Bipbip.logger.info "Running plugin #{plugin.name} with config #{config}"
      plugin.run(config)
    end

  end
end
