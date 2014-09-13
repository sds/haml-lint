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

    # Returns the simple name for this linter.
    def name
      self.class.name.split('::').last
    end

    private

    attr_reader :config

    def add_lint(node, message = nil)
      @lints << Lint.new(self, parser.filename, node.line, message || self.message)
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
      return false unless string
      Haml::Util.contains_interpolation?(string)
    end

    # Returns whether this tag node has inline script, e.g. is of the form
    # %tag= ...
    #
    # @param tag_node [Haml::Parser::ParseNode]
    # @return [true,false]
    def tag_has_inline_script?(tag_node)
      tag_with_inline_content = tag_with_inline_text(tag_node)
      return false unless inline_content = inline_node_content(tag_node)
      return false unless index = tag_with_inline_content.rindex(inline_content)

      index -= 1
      index -= 1 while [' ', '"', "'"].include?(tag_with_inline_content[index])

      tag_with_inline_content[index] == '='
    end

    # Returns whether the inline content for a node is a string.
    #
    # For example, the following node has a literal string:
    #
    #   %tag= "A literal #{string}"
    #
    # whereas this one does not:
    #
    #   %tag A literal #{string}
    #
    # @param node [Haml::Parser::ParseNode]
    # @return [true,false]
    def inline_content_is_string?(node)
      tag_with_inline_content = tag_with_inline_text(node)
      inline_content = inline_node_content(node)

      index = tag_with_inline_content.rindex(inline_content) - 1

      %w[' "].include?(tag_with_inline_content[index])
    end

    # Get the inline content for this node.
    #
    # Inline content is the content that appears inline right after the
    # tag/script. For example, in the code below...
    #
    #   %tag Some inline content
    #
    # ..."Some inline content" would be the inline content.
    #
    # @param node [Haml::Parser::ParseNode]
    # @return [String]
    def inline_node_content(node)
      inline_content = node.value[:value]

      if contains_interpolation?(inline_content)
        strip_surrounding_quotes(inline_content)
      else
        inline_content
      end
    end

    # Gets the next node following this node, ascending up the ancestor chain
    # recursively if this node has no siblings.
    #
    # @param node [Haml::Parser::ParseNode]
    # @return [Haml::Parser::ParseNode,nil]
    def next_node(node)
      return unless node
      siblings = node.parent ? node.parent.children : [node]

      next_sibling = siblings[siblings.index(node) + 1] if siblings.count > 1
      return next_sibling if next_sibling

      next_node(node.parent)
    end

    # Extracts all text for a tag node and normalizes it, including additional
    # lines following commas or multiline bar indicators ('|')
    #
    # @param tag_node [Haml::Parser::ParseNode]
    # @return [String] source code of original parse node
    def tag_with_inline_text(tag_node)
      # Next node is either the first child or the "next node" (node's sibling
      # or next sibling of some ancestor)
      next_node_line = [
        [tag_node.children.first, next_node(tag_node)].compact.map(&:line),
        parser.lines.count + 1,
      ].flatten.min

      # Normalize each of the lines to ignore the multiline bar (|) and
      # excess whitespace
      parser.lines[(tag_node.line - 1)...(next_node_line - 1)].map do |line|
        line.strip.gsub(/\|\z/, '').rstrip
      end.join(' ')
    end

    # Extracts just the tag definition from a tag node.
    #
    # For example, it will extract `%tag.class#id` from
    # `%tag.class#id{ attr: 'something' } Some inline content`.
    def tag_definition(tag_node)
      parser.lines[tag_node.line - 1][/\s*([^{( $]+)/, 1]
    end
  end
end
