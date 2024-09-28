# frozen_string_literal: true

require_relative 'reporter/hooks'

module HamlLint
  # Abstract lint reporter. Subclass and override {#display_report} to
  # implement a custom lint reporter.
  #
  # @abstract
  class Reporter
    include Reporter::Hooks

    # The CLI names of all configured reporters.
    #
    # @return [Array<String>]
    def self.available
      descendants.flat_map do |reporter|
        available = reporter.available
        available.unshift(reporter) if reporter.available?
        available
      end
    end

    # A flag for whether to show the reporter on the command line.
    #
    # @return [Boolean]
    def self.available?
      true
    end

    # The name of the reporter as passed from the CLI.
    #
    # @return [String]
    def self.cli_name
      name
        .split('::')
        .last
        .sub(/Reporter$/, '')
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1-\2')
        .gsub(/([a-z\d])([A-Z])/, '\1-\2')
        .downcase
    end

    # Creates the reporter that will display the given report.
    #
    # @param logger [HamlLint::Logger]
    def initialize(logger)
      @log = logger
    end

    # Implemented by subclasses to display lints from a {HamlLint::Report}.
    #
    # @param report [HamlLint::Report]
    def display_report(report)
      raise NotImplementedError,
            "Implement `display_report` to display #{report}"
    end

    # Keep tracking all the descendants of this class for the list of available
    # reporters.
    #
    # @return [Array<Class>]
    def self.descendants
      @descendants ||= []
    end

    # Executed when this class is subclassed.
    #
    # @param descendant [Class]
    def self.inherited(descendant)
      descendants << descendant
    end

    private

    # @return [HamlLint::Logger] logger to send output to
    attr_reader :log
  end
end
