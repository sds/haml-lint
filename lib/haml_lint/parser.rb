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
      original_tree = Haml::Parser.new(@contents, Haml::Options.new).parse

      # Remove the trailing empty HAML comment that the parser creates to signal
      # the end of the HAML document
      original_tree.children.pop

      @node_transformer = HamlLint::NodeTransformer.new(self)
      @tree = convert_tree(original_tree)
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

    # Converts a HAML parse tree to a tree of {HamlLint::Tree::Node} objects.
    #
    # This provides a cleaner interface with which the linters can interact with
    # the parse tree.
    def convert_tree(haml_node, parent = nil)
      new_node = @node_transformer.transform(haml_node)
      new_node.parent = parent

      new_node.children = haml_node.children.map do |child|
        convert_tree(child, new_node)
      end

      new_node
    end
  end
end
