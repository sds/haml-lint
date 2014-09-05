module HamlLint
  # Base implementation for all lint checks.
  class Linter
    include HamlVisitor

    attr_reader :parser, :lints

    # @param config [Hash] configuration for this linter
    def initialize(config)
      @config = config
      @lints = []
    end

    def run(parser)
      @parser = parser
      visit(parser.tree)
    end

    def message
      nil # Subclasses can implement if they want a default lint message
    end

    # Returns the simple name for this linter.
    def name
      self.class.name.split('::').last
    end

  private

    attr_reader :config

    def add_lint(node, message = nil)
      @lints << Lint.new(parser.filename, node.line, message || self.message)
    end

    # Remove the surrounding double quotes from a string, ignoring any
    # leading/trailing whitespace.
    #
    # @param string [String]
    # @return [String] stripped with leading/trailing double quotes removed.
    def strip_surrounding_quotes(string)
      string[/\A\s*"(.*)"\s*\z/, 1]
    end

    # Returns whether a string contains any interpolation.
    #
    # @param string [String]
    # @return [true,false]
    def contains_interpolation?(string)
      Haml::Util.contains_interpolation?(string)
    end
  end
end
