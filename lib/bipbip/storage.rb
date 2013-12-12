module Bipbip

  class Storage

    attr_accessor :name
    attr_accessor :config

    def initialize(name, config)
      @name = name.to_s
      @config = config.to_h
    end

    def setup_plugin
      raise 'Missing method setup_plugin'
    end

  end
end
