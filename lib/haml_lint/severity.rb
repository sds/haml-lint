# frozen_string_literal: true

require 'delegate'

module HamlLint
  # Models the severity of a lint
  class Severity < SimpleDelegator
    include Comparable

    SEVERITY_ERROR = :error
    SEVERITY_WARNING = :warning

    COLORS = { error: :red, warning: :yellow }.freeze
    MARKS = { error: 'E', warning: 'W' }.freeze
    NAMES = [SEVERITY_WARNING, SEVERITY_ERROR].freeze

    # Creates a new severity for a lint
    #
    # @example
    #   HamlLint::Severity.new(:warning)
    #
    # @api public
    # @param name [Symbol] the name of the severity level
    def initialize(name)
      name = name.name if name.is_a?(Severity)
      name ||= :warning
      fail Exceptions::UnknownSeverity, "Unknown severity: #{name}" unless NAMES.include?(name)
      super
    end

    # The color of the mark in reporters.
    #
    # @return [Symbol]
    def color
      COLORS[__getobj__]
    end

    # Checks whether the severity is an error
    #
    # @example
    #   HamlLint::Severity.new(:error).error? #=> true
    #
    # @api public
    # @return [Boolean]
    def error?
      __getobj__ == :error
    end

    # The level of severity for the lint
    #
    # @api public
    # @return [Integer]
    def level
      NAMES.index(__getobj__) + 1
    end

    # The symbol to use in a {HamlLint::Reporter::ProgressReporter}.
    #
    # @returns [String]
    def mark
      MARKS[__getobj__]
    end

    # The colorized symbol to use in a reporter.
    #
    # @returns [String]
    def mark_with_color
      Rainbow.global.wrap(mark).public_send(color)
    end

    # The name of the severity.
    #
    # @returns [Symbol]
    def name
      __getobj__
    end

    # Checks whether the severity is a warning
    #
    # @example
    #   HamlLint::Severity.new(:warning).warning? #=> true
    #
    # @api public
    # @return [Boolean]
    def warning?
      __getobj__ == :warning
    end

    # Compares the severity to another severity or a symbol
    #
    # @return [Integer]
    def <=>(other)
      other = Severity.new(other) unless other.respond_to?(:level)
      level <=> other.level
    end
  end
end
