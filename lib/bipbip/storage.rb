module Bipbip
  class Storage
    attr_accessor :name
    attr_accessor :config

    def self.factory(name, config)
      require "bipbip/storage/#{Bipbip::Helper.name_to_filename(name)}"
      Storage.const_get(Bipbip::Helper.name_to_classname(name)).new(name, config)
    end

    def initialize(name, config)
      @name = name.to_s
      @config = config.to_hash
    end

    def setup_plugin(_plugin)
      fail 'Missing method setup_plugin'
    end

    def store_sample(_plugin, _time, _data)
      fail 'Missing method store_sample'
    end

    private

    def log(severity, message)
      Bipbip.logger.add(severity, message, name.to_s)
    end
  end
end
