$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'haml_lint/constants'
require 'haml_lint/version'

Gem::Specification.new do |s|
  s.name             = 'haml_lint'
  s.version          = HamlLint::VERSION
  s.license          = 'MIT'
  s.summary          = 'HAML lint tool'
  s.description      = 'Configurable tool for writing clean and consistent HAML'
  s.authors          = ['Brigade Engineering', 'Shane da Silva']
  s.email            = ['eng@brigade.com', 'shane.dasilva@brigade.com']
  s.homepage         = HamlLint::REPO_URL

  s.require_paths    = ['lib']

  s.executables      = ['haml-lint']

  s.files            = Dir['config/**.yml'] +
                       Dir['lib/**/*.rb']

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'haml', '>= 4.0', '< 5.1'
  s.add_dependency 'rainbow'
  s.add_dependency 'rake', '>= 10', '< 13'
  s.add_dependency 'rubocop', '>= 0.49.0'
  s.add_dependency 'sysexits', '~> 1.1'
end
