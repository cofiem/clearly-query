# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'clearly/query/version'

Gem::Specification.new do |spec|
  spec.name          = 'clearly-query'
  spec.version       = Clearly::Query::VERSION
  spec.authors       = ['Mark Cottman-Fields']
  spec.email         = ['cofiem@gmail.com']
  spec.summary       = %q{A library for constructing an sql query from a hash.}
  spec.description   = %q{A library for constructing an sql query from a hash. Uses a strict, yet flexible specification.}
  spec.homepage      = 'https://github.com/cofiem/clearly-query'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  
  spec.required_ruby_version = '>= 2.0.0'

  spec.add_runtime_dependency 'arel', '~> 6.0'
  spec.add_runtime_dependency 'activesupport', '~> 4.2'
  spec.add_runtime_dependency 'activerecord', '~> 4.2'

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 11.2'
  spec.add_development_dependency 'guard-rspec', '~> 4.6'
  spec.add_development_dependency 'guard-yard', '~> 2.1'
  spec.add_development_dependency 'simplecov', '~> 0.11'
  spec.add_development_dependency 'sqlite3', '~> 1.3'
  spec.add_development_dependency 'zonebie', '~> 0.5'
  spec.add_development_dependency 'database_cleaner', '~> 1.5'
end
