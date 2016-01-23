if ENV['TRAVIS']
  # When running in Travis, report coverage stats to Coveralls.
  require 'coveralls'
  Coveralls.wear!
else
  # Otherwise render coverage information in coverage/index.html and display
  # coverage percentage in the console.
  require 'simplecov'
end

require 'haml_lint'
require 'rspec/its'
require 'nokogiri'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.include DirectorySpecHelpers

  config.expect_with :rspec do |c|
    c.syntax = [:expect, :should]
  end

  config.mock_with :rspec do |c|
    c.syntax = :should
  end
end
