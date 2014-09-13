require 'haml'

module HamlLint
  # Parses a HAML document for inspection by linters.
  class Parser
    attr_reader :contents, :filename, :lines, :tree

    def initialize(haml_or_filename, options = {})
      if File.exist?(haml_or_filename)
        @filename = haml_or_filename
        @contents = File.read(haml_or_filename)
      else
        @contents = haml_or_filename
      end

      if options['skip_frontmatter'] &&
        @contents =~ /
          # from the start of the string
          \A
          # first-capture match --- followed by optional whitespace up
          # to a newline then 0 or more chars followed by an optional newline.
          # this matches the --- and the contents of the frontmatter
          (---\s*\n.*?\n?)
          # from the start of the line
          ^
          # second capture match --- or ... followed by optional whitespace
          # and newline. This matches the closing --- for the frontmatter.
          (---|\.\.\.)\s*$\n?/mx
        @contents = $POSTMATCH
      end

      @lines = @contents.split("\n")
      @tree = Haml::Parser.new(@contents, Haml::Options.new).parse

      # Remove the trailing empty HAML comment that the parser creates to signal
      # the end of the HAML document
      @tree.children.pop
    end
  end
end
