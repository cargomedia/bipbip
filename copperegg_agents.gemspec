require File.expand_path('../lib/copperegg_agents/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'copperegg_agents'
  s.version     = CoppereggAgents::VERSION
  s.summary     = "CopperEgg RevealMetrics custom agents"
  s.description = "Custom agent plugins for CopperEgg RevealMetrics"
  s.authors     = ["Cargo Media"]
  s.email       = 'dev@cargomedia.ch'
  s.files       = Dir['LICENSE*', 'README*', '{bin,lib}/**/*']
  s.executables = ['copperegg_agents']
  s.homepage    = 'https://github.com/cargomedia/copperegg_agents'
  s.license     = 'MIT'
  s.add_runtime_dependency 'copperegg', '~> 0.6.0'
  s.add_runtime_dependency 'memcached'
end
