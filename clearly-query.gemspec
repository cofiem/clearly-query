# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'clearly-query/version'

Gem::Specification.new do |spec|
  spec.name          = 'clearly-query'
  spec.version       = ClearlyQuery::VERSION
  spec.authors       = ['cofiem']
  spec.email         = ['qut.bioacoustics.research+mark@gmail.com']
  spec.summary       = %q{A library for constructing an sql query from a hash.}
  spec.description   = %q{A library for constructing an sql query from a hash. Uses a strict, yet flexible specification.}
  spec.homepage      = 'https://github.com/cofiem/clearly-query'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'arel', '~> 6'
  spec.add_runtime_dependency 'activesupport', '~> 4'

  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'guard-rspec', '~> 4.5'
  spec.add_development_dependency 'guard-yard', '~> 2.1'
  spec.add_development_dependency 'simplecov', '~> 0.10'
end
