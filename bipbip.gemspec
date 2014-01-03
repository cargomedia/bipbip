require File.expand_path('../lib/bipbip/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'bipbip'
  s.version     = Bipbip::VERSION
  s.summary     = 'Gather services data and store in CopperEgg'
  s.description = 'Agent to collect data for common server programs and push them to CopperEgg'
  s.authors     = ["Cargo Media"]
  s.email       = 'hello@cargomedia.ch'
  s.files       = Dir['LICENSE*', 'README*', '{bin,lib,data}/**/*']
  s.executables = ['bipbip']
  s.homepage    = 'https://github.com/cargomedia/bipbip'
  s.license     = 'MIT'

  s.add_runtime_dependency 'copperegg', '~> 0.6.0'
  s.add_runtime_dependency 'memcached'
  s.add_runtime_dependency 'mysql2'
  s.add_runtime_dependency 'redis'
  s.add_runtime_dependency 'gearman-ruby'
  s.add_runtime_dependency 'resque', '~> 1.25'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~> 2.0'
end
