require 'delegate'

module HamlLint
  # Models the severity of a lint
  class Severity < SimpleDelegator
    include Comparable

    SEVERITY_ERROR = :error
    SEVERITY_WARNING = :warning

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
