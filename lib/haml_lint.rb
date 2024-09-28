# frozen_string_literal: true

# Need to load haml before we can reference some Haml modules in our code
require 'haml'

require_relative 'haml_lint/constants'
require_relative 'haml_lint/exceptions'
require_relative 'haml_lint/configuration'
require_relative 'haml_lint/configuration_loader'
require_relative 'haml_lint/document'
require_relative 'haml_lint/haml_visitor'
require_relative 'haml_lint/lint'
require_relative 'haml_lint/linter_registry'
require_relative 'haml_lint/ruby_parser'
require_relative 'haml_lint/linter'
require_relative 'haml_lint/logger'
require_relative 'haml_lint/reporter'
require_relative 'haml_lint/report'
require_relative 'haml_lint/linter_selector'
require_relative 'haml_lint/file_finder'
require_relative 'haml_lint/runner'
require_relative 'haml_lint/utils'
require_relative 'haml_lint/version'
require_relative 'haml_lint/version_comparer'
require_relative 'haml_lint/severity'

# Lead all extensions to external source code
Dir[File.expand_path('haml_lint/extensions/*.rb', File.dirname(__FILE__))].sort.each do |file|
  require file
end

# Load all parse tree node classes
require_relative 'haml_lint/tree/node'
require_relative 'haml_lint/node_transformer'
Dir[File.expand_path('haml_lint/tree/*.rb', File.dirname(__FILE__))].sort.each do |file|
  require file
end

# Load all linters
Dir[File.expand_path('haml_lint/linter/*.rb', File.dirname(__FILE__))].sort.each do |file|
  require file
end

# Load all reporters
Dir[File.expand_path('haml_lint/reporter/*.rb', File.dirname(__FILE__))].sort.each do |file|
  require file
end

# Load all the chunks for RubyExtraction
require_relative 'haml_lint/ruby_extraction/base_chunk'
Dir[File.expand_path('haml_lint/ruby_extraction/*.rb', File.dirname(__FILE__))].sort.each do |file|
  require file
end
