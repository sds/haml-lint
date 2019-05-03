# frozen_string_literal: true

module HamlLint
  # Handles linter configuration transformation via Haml comments.
  class Directive
    LINTER_REGEXP = /(?:[A-Z]\w+)/

    DIRECTIVE_REGEXP = /
      # "haml-lint:" with optional spacing
      \s*haml-lint\s*:\s*

      # The mode - either disable or enable
      (?<mode>(?:dis|en)able)\b\s*

      # "all" or a comma-separated list (with optional spaces) of linters
      (?<linters>all | (?:#{LINTER_REGEXP}\s*,\s*)* #{LINTER_REGEXP})
    /x

    # Constructs a directive from source code as a given line.
    #
    # @param source [String] the source code to analyze
    # @param line [Integer] the line number the source starts at
    # @return [HamlLint::Directive]
    def self.from_line(source, line)
      match = DIRECTIVE_REGEXP.match(source)

      if match
        new(source, line, match[:mode], match[:linters].split(/\s*,\s*/))
      else
        Null.new(source, line)
      end
    end

    # Instantiates a new {HamlLint::Directive}
    #
    # @api semipublic
    # @param source [String] the source code to analyze
    # @param line [Integer] the line number the source starts at
    # @param mode [String] the type of directive, one of "disable" or "enable"
    # @param linters [Array<String>] the name of the linters to act upon
    def initialize(source, line, mode, linters)
      @source = source
      @line = line
      @mode = mode
      @linters = linters
    end

    # The names of the linters to act upon.
    #
    # @return [String]
    attr_reader :linters

    # The mode of the directive. One of "disable" or "enable".
    #
    # @return [String]
    attr_reader :mode

    # Checks whether a directive is equivalent to another.
    #
    # @api public
    # @param other [HamlLint::Directive] the other directive
    # @return [true, false]
    def ==(other)
      super unless other.is_a?(HamlLint::Directive)

      mode == other.mode && linters == other.linters
    end

    # Checks whether this is a disable directive.
    #
    # @return [true, false]
    def disable?
      mode == 'disable'
    end

    # Checks whether this is an enable directive.
    #
    # @return [true, false]
    def enable?
      mode == 'enable'
    end

    # Formats the directive for display in a console.
    #
    # @return [String]
    def inspect
      "#<HamlLint::Directive(mode=#{mode}, linters=#{linters})>"
    end

    # A null representation of a directive.
    class Null < Directive
      # Instantiates a new null directive.
      #
      # @param source [String] the source code to analyze
      # @param line [Integer] the line number the source starts at
      def initialize(source, line)
        @source = source
        @line = line
      end

      # Stubs out the disable check as false.
      #
      # @return [false]
      def disable?
        false
      end

      # Stubs out the ensable check as false.
      #
      # @return [false]
      def enable?
        false
      end

      # Formats the null directive for display in a console.
      #
      # @return [String]
      def inspect
        '#<HamlLint::Directive::Null>'
      end

      # Stubs out the linters.
      #
      # @return [Array]
      def linters
        []
      end
    end
  end
end
