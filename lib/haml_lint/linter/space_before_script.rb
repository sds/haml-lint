module HamlLint
  # Checks for Ruby script in HAML templates with no space after the `=`/`-`.
  class Linter::SpaceBeforeScript < Linter
    include LinterRegistry

    def visit_tag(node) # rubocop:disable CyclomaticComplexity
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
        if text_without_quotes = strip_surrounding_quotes(text)
          return unless index = tag_with_text.rindex(text_without_quotes)
        end
      end

      # Check if the character before the start of the script is a space
      # (need to do it this way as the parser strips whitespace from node)
      return unless tag_with_text[index - 1] != ' '

      add_lint(node, DESCRIPTION_FORMAT % '=')
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
  end
end
