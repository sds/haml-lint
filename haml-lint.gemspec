$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'haml_lint/constants'
require 'haml_lint/version'

Gem::Specification.new do |s|
  s.name             = 'haml-lint'
  s.version          = HamlLint::VERSION
  s.license          = 'MIT'
  s.summary          = 'HAML lint tool'
  s.description      = 'Opinionated tool for writing clean and consistent HAML'
  s.authors          = ['Causes Engineering', 'Shane da Silva']
  s.email            = ['eng@causes.com', 'shane@causes.com']
  s.homepage         = HamlLint::REPO_URL

  s.require_paths    = ['lib']

  s.executables      = ['haml-lint']

  s.files            = Dir['config/**.yml'] +
                       Dir['lib/**/*.rb']

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'haml', '~> 4.0'
  s.add_dependency 'rubocop', '>= 0.25.0'
  s.add_dependency 'sysexits', '~> 1.1'

  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rspec-its', '~> 1.0'
  s.add_development_dependency 'rubocop', '0.26.0' # Pin for Travis builds
end
