module HamlLint
  # Checks for Ruby script in HAML templates with no space after the `=`/`-`.
  class Linter::SpaceBeforeScript < Linter
    include LinterRegistry

    def visit_tag(node)
      # If this tag has inline script
      return unless node.value[:parse]

      text = node.value[:value].to_s
      return if text.empty?

      tag_with_text = tag_with_inline_text(node)

      unless index = tag_with_text.rindex(text)
        # For tags with inline text that contain interpolation, the parser
        # converts them to inline script by surrounding them in string quotes,
        # e.g. `%p Hello #{name}` becomes `%p= "Hello #{name}"`, causing the
        # above search to fail. Check for this case by removing added quotes.
        if text_without_quotes = text[/\A"(.*)"\z/, 1]
          return unless index = tag_with_text.rindex(text_without_quotes)
        end
      end

      # Check if the character before the start of the script is a space
      # (need to do it this way as the parser strips whitespace from node)
      if tag_with_text[index - 1] != ' '
        add_lint(node, DESCRIPTION_FORMAT % '=')
      end
    end

    def visit_script(node)
      # Plain text nodes with interpolation are converted to script nodes, so we
      # need to ignore them here.
      return unless parser.lines[node.line - 1].lstrip.start_with?('=')
      add_lint(node, DESCRIPTION_FORMAT % '=') if missing_space?(node)
    end

    def visit_silent_script(node)
      add_lint(node, DESCRIPTION_FORMAT % '-') if missing_space?(node)
    end

  private

    DESCRIPTION_FORMAT = 'The %s symbol should have one space separating it from code'

    def missing_space?(node)
      text = node.value[:text].to_s
      text[0] != ' ' if text
    end

    # Extracts all text for a tag node and normalizes it, including additional
    # lines following commas or multiline bar indicators ('|')
    def tag_with_inline_text(node)
      # Next node is either the first child or the "next node" (node's sibling
      # or next sibling of some ancestor)
      next_node_line = [
        [next_node(node), node.children.first].compact.map(&:line),
        parser.lines.count + 1,
      ].flatten.min

      # Normalize each of the lines to ignore the multiline bar (|) and
      # excess whitespace
      parser.lines[(node.line - 1)...(next_node_line - 1)].map do |line|
        line.strip.gsub(/\|\z/, '').rstrip
      end.join(' ')
    end

    # Gets the next node following this node, ascending up the ancestor chain
    # recursively if this node has no siblings.
    def next_node(node)
      return unless node
      siblings = node.parent.children

      next_sibling = siblings[siblings.index(node) + 1] if siblings.count > 1

      if next_sibling
        next_sibling
      else
        next_node(node.parent)
      end
    end
  end
end
