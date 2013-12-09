module CoppereggAgents
  require 'copperegg'
  require 'yaml'
  require 'logger'
  require 'socket'

  require 'copperegg_agents/version'
  require 'copperegg_agents/interruptible_sleep'
  require 'copperegg_agents/agent'
  require 'copperegg_agents/plugin'
  require 'copperegg_agents/plugin/memcached'
  require 'copperegg_agents/plugin/mysql'
  require 'copperegg_agents/plugin/redis'

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
