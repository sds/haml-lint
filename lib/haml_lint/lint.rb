module HamlLint
  # Contains information about a problem or issue with a HAML document.
  class Lint
    attr_reader :filename, :line, :message, :severity

    def initialize(filename, line, message, severity = :warning)
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
