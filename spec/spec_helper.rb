# frozen_string_literal: true

if ENV['TRAVIS']
  # When running in Travis, report coverage stats to Coveralls.
  require 'coveralls'
  Coveralls.wear!
else
  # Otherwise render coverage information in coverage/index.html and display
  # coverage percentage in the console.
  require 'simplecov'
end

# Disable colors in tests because we don't normally want to test it
require 'rainbow'
Rainbow.enabled = false

require 'haml_lint'
require 'haml_lint/spec'
require 'rspec/its'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.include DirectorySpecHelpers

  config.expect_with :rspec do |c|
    c.syntax = %i[expect should]
  end

  config.mock_with :rspec do |c|
    c.syntax = :should
  end
end
