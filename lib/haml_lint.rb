module HamlLint
  autoload :CLI, 'haml_lint/cli'
  autoload :Parser, 'haml_lint/parser'
  autoload :Lint, 'haml_lint/lint'
  autoload :LinterRegistry, 'haml_lint/linter_registry'
  autoload :Linter, 'haml_lint/linter'
  autoload :Reporter, 'haml_lint/reporter'
  autoload :Runner, 'haml_lint/runner'
  autoload :Utils, 'haml_lint/utils'
  autoload :VERSION, 'haml_lint/version'

  require 'haml'

  # Load all linters
  Dir[File.expand_path('haml_lint/linter/*.rb', File.dirname(__FILE__))].each do |file|
    require file
  end

  # Load all reporters
  Dir[File.expand_path('haml_lint/reporter/*.rb', File.dirname(__FILE__))].each do |file|
    require file
  end
end
