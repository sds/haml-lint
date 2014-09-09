require 'haml'

module HamlLint
  # Parses a HAML document for inspection by linters.
  class Parser
    attr_reader :contents, :filename, :lines, :tree

    # Creates a parser containing the parse tree of a HAML document.
    #
    # @param haml_or_filename [String]
    # @param options [Hash]
    # @option options [true,false] 'skip_frontmatter' Whether to skip
    #   frontmatter included by frameworks such as Middleman or Jekyll
    def initialize(haml_or_filename, options = {})
      if File.exist?(haml_or_filename)
        @filename = haml_or_filename
        @contents = File.read(haml_or_filename)
      else
        @contents = haml_or_filename
      end

      process_options(options)

      @lines = @contents.split("\n")
      @tree = Haml::Parser.new(@contents, Haml::Options.new).parse

      # Remove the trailing empty HAML comment that the parser creates to signal
      # the end of the HAML document
      @tree.children.pop
    end

    private

    def process_options(options)
      if options['skip_frontmatter'] &&
        @contents =~ /
          # From the start of the string
          \A
          # First-capture match --- followed by optional whitespace up
          # to a newline then 0 or more chars followed by an optional newline.
          # This matches the --- and the contents of the frontmatter
          (---\s*\n.*?\n?)
          # From the start of the line
          ^
          # Second capture match --- or ... followed by optional whitespace
          # and newline. This matches the closing --- for the frontmatter.
          (---|\.\.\.)\s*$\n?/mx
        @contents = $POSTMATCH
      end
    end
  end
end
