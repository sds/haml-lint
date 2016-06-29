module HamlLint
  # Defines the severity class
  class Severity
    include Comparable

    SEVERITY_WARNING = :warning
    SEVERITY_ERROR = :error

    NAMES = [SEVERITY_WARNING, SEVERITY_ERROR].freeze

    attr_reader :name

    # @api private
    def initialize(name)
      fail ArgumentError, "Unknown severity: #{name}" unless NAMES.include?(name)

      @name = name.freeze
      freeze
    end

    def level
      NAMES.index(@name) + 1
    end

    # @api private
    def to_s
      @name.to_s
    end

    # @api private
    def ==(other)
      return @name == other if other.is_a?(Symbol)

      @name == other.name
    end

    # @api private
    def <=>(other)
      level <=> other.level
    end

    def error?
      @name == SEVERITY_ERROR
    end
  end
end
