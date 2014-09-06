module HamlLint
  # Contains information about a problem or issue with a HAML document.
  class Lint
    attr_reader :filename, :line, :linter, :message, :severity

    # Creates a new lint.
    #
    # @param linter [HamlLint::Linter]
    # @param filename [String]
    # @param line [Fixnum]
    # @param message [String]
    # @param severity [Symbol]
    def initialize(linter, filename, line, message, severity = :warning)
      @linter   = linter
      @filename = filename
      @line     = line
      @message  = message
      @severity = severity
    end

    def error?
      @severity == :error
    end
  end
end
