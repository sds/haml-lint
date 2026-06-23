# frozen_string_literal: true

module HamlLint
  # Checks for Ruby script in Haml templates with no space after the `=`/`-`.
  class Linter::SpaceBeforeScript < Linter
    include LinterRegistry

    supports_autocorrect(true)

    MESSAGE_FORMAT = 'The %s symbol should have one space separating it from code'

    ALLOWED_SEPARATORS = [' ', '#'].freeze

    def visit_tag(node) # rubocop:disable Metrics/CyclomaticComplexity
      # If this tag has inline script
      return unless node.contains_script?

      text = node.script.strip
      return if text.empty?

      tag_with_text = tag_with_inline_text(node)

      # For tags with inline text that contain interpolation, the parser
      # converts them to inline script by surrounding them in string quotes,
      # e.g. `%p Hello #{name}` becomes `%p= "Hello #{name}"`, causing the
      # above search to fail. Check for this case by removing added quotes.
      if !(index = tag_with_text.rindex(text)) && !((text_without_quotes = strip_surrounding_quotes(text)) &&
                     (index = tag_with_text.rindex(text_without_quotes)))
        return
      end

      return if tag_with_text[index] == '#' # Ignore code comments

      # Check if the character before the start of the script is a space
      # (need to do it this way as the parser strips whitespace from node)
      return unless tag_with_text[index - 1] != ' '

      corrected = correct_inline_script(node, text)
      record_lint(node, MESSAGE_FORMAT % '=', corrected: corrected)
    end

    def visit_script(node)
      # Plain text nodes with interpolation are converted to script nodes, so we
      # need to ignore them here.
      return unless document.source_lines[node.line - 1].lstrip.start_with?('=')
      return unless missing_space?(node)

      record_lint(node, MESSAGE_FORMAT % '=', corrected: correct_leading_marker(node, '='))
    end

    def visit_silent_script(node)
      return unless missing_space?(node)

      record_lint(node, MESSAGE_FORMAT % '-', corrected: correct_leading_marker(node, '-'))
    end

    private

    def missing_space?(node)
      text = node.script
      !ALLOWED_SEPARATORS.include?(text[0]) if text
    end

    # Inserts one space after a leading `=`/`-` marker.
    #
    # @return [Boolean]
    def correct_leading_marker(node, marker)
      index = node.line - 1
      line = autocorrected_lines[index]
      escaped = Regexp.escape(marker)
      correct_line(index, line.sub(/\A(\s*#{escaped})(?=[^\s#{escaped}])/, '\1 '))
    end

    # Inserts a space after the `=` marker introducing a tag's inline script.
    #
    # @return [Boolean]
    def correct_inline_script(node, text)
      index = node.line - 1
      line = autocorrected_lines[index]

      pos = line.rindex("=#{text}")
      if pos.nil? && (unquoted = strip_surrounding_quotes(text))
        pos = line.rindex("=#{unquoted}")
      end
      return false unless pos

      correct_line(index, "#{line[0..pos]} #{line[(pos + 1)..]}")
    end
  end
end
