# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'haml_lint/version'

Gem::Specification.new do |s|
  s.name        = 'haml-lint'
  s.version     = HamlLint::VERSION
  s.license     = 'MIT'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Causes Engineering', 'Shane da Silva']
  s.email       = ['eng@causes.com', 'shane@causes.com']
  s.homepage    = 'http://github.com/causes/haml-lint'
  s.summary     = 'HAML lint tool'
  s.description = 'Opinionated tool to help you write better HAML'

  s.files         = Dir['lib/**/*.rb']
  s.executables   = ['haml-lint']
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'colorize', '0.5.8'
  s.add_dependency 'haml', '4.0.3'
  s.add_dependency 'rubocop', '>= 0.15.0'

  s.add_development_dependency 'rspec', '2.13.0'
end
