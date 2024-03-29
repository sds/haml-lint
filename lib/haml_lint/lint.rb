# frozen_string_literal: true

module HamlLint
  # Contains information about a problem or issue with a HAML document.
  class Lint
    # @return [Boolean] If the error was corrected by auto-correct
    attr_reader :corrected

    # @return [String] file path to which the lint applies
    attr_reader :filename

    # @return [String] line number of the file the lint corresponds to
    attr_reader :line

    # @return [SlimLint::Linter] linter that reported the lint
    attr_reader :linter

    # @return [String] error/warning message to display to user
    attr_reader :message

    # @return [Symbol] whether this lint is a warning or an error
    attr_reader :severity

    # Creates a new lint.
    #
    # @param linter [HamlLint::Linter]
    # @param filename [String]
    # @param line [Fixnum]
    # @param message [String]
    # @param severity [Symbol]
    def initialize(linter, filename, line, message, severity = :warning, corrected: false) # rubocop:disable Metrics/ParameterLists
      @linter   = linter
      @filename = filename
      @line     = line || 0
      @message  = message
      @severity = Severity.new(severity)
      @corrected = corrected
    end

    # Return whether this lint has a severity of error.
    #
    # @return [Boolean]
    def error?
      @severity.error?
    end

    def inspect
      "#{self.class.name}(corrected=#{corrected}, filename=#{filename}, line=#{line}, " \
        "linter=#{linter.class.name}, message=#{message}, severity=#{severity})"
    end
  end
end
