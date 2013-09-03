module HamlLint
  class Lint
    attr_reader :filename, :line, :message

    def initialize(filename, line, message)
      @filename = filename
      @line = line
      @message = message
    end
  end
end
