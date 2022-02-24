# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/bin/'
  add_filter '/spec/'

  if ENV['CI']
    require 'simplecov-lcov'

    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = 'coverage/lcov.info'
    end

    formatter SimpleCov::Formatter::LcovFormatter
  end
end

# Disable colors in tests because we don't normally want to test it
require 'rainbow'
Rainbow.enabled = false

require 'haml_lint'
require 'haml_lint/spec'
require 'rspec/its'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].sort.each { |f| require f }

RSpec.configure do |config|
  config.include DirectorySpecHelpers

  config.expect_with :rspec do |c|
    c.syntax = %i[expect should]
  end

  config.mock_with :rspec do |c|
    c.syntax = :should
  end
end
