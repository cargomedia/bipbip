module CoppereggAgents
  require 'copperegg'
  require 'yaml'
  require 'logger'
  require 'socket'

  require 'interruptible_sleep'
  require 'agent'
  require 'plugin'
  require 'plugin/memcached'

  def self.logger
    @logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.fqdn
    @fqdn ||= Socket.gethostbyname(Socket.gethostname).first
  end
end
