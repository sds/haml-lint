# frozen_string_literal: true

$LOAD_PATH << File.expand_path('lib', __dir__)
require 'haml_lint/constants'
require 'haml_lint/version'

Gem::Specification.new do |s|
  s.name             = 'haml_lint'
  s.version          = HamlLint::VERSION
  s.license          = 'MIT'
  s.summary          = 'HAML lint tool'
  s.description      = 'Configurable tool for writing clean and consistent HAML'
  s.authors          = ['Shane da Silva']
  s.email            = ['shane@dasilva.io']
  s.homepage         = HamlLint::REPO_URL

  s.require_paths    = ['lib']

  s.executables      = ['haml-lint']

  s.files            = Dir['config/**.yml'] +
                       Dir['lib/**/*.rb']

  s.required_ruby_version = '>= 3.0'

  s.add_dependency 'haml', '>= 5.0'
  s.add_dependency 'parallel', '~> 1.10'
  s.add_dependency 'rainbow'
  s.add_dependency 'rubocop', '>= 1.0'
  s.add_dependency 'sysexits', '~> 1.1'

  s.metadata = {
    'bug_tracker_uri' => 'https://github.com/sds/haml-lint/issues',
    'changelog_uri' => 'https://github.com/sds/haml-lint/blob/main/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/sds/haml-lint',
  }
end
