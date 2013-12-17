module Bipbip
  require 'rubygems'  # For ruby < 1.9

  require 'copperegg'
  require 'yaml'
  require 'json/pure'
  require 'logger'
  require 'socket'

  require 'interruptible_sleep'

  require 'bipbip/version'
  require 'bipbip/helper'
  require 'bipbip/agent'
  require 'bipbip/storage'
  require 'bipbip/plugin'

  def self.logger
    @logger || Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.fqdn
    @fqdn ||= Socket.gethostbyname(Socket.gethostname).first rescue Socket.gethostname
  end
end
