# frozen_string_literal: true

require_relative 'hash_reporter'

module HamlLint
  # Outputs report as a JSON document.
  class Reporter::JsonReporter < Reporter::HashReporter
    # Ensures that the CLI is able to use the the reporter.
    #
    # @return [true]
    def self.available?
      true
    end

    def display_report(report)
      log.log super.to_json
    end
  end
end
