# frozen_string_literal: true

module HamlLint
  # Checks for unnecessary outputting of strings in Ruby script tags.
  #
  # For example, the following two code snippets are equivalent, but the latter
  # is more concise (and thus preferred):
  #
  #   %tag= "Some #{expression}"
  #   %tag Some #{expression}
  class Linter::UnnecessaryStringOutput < Linter
    include LinterRegistry

    supports_autocorrect(true)
    autocorrect_safe(false)

    MESSAGE = '`= "..."` should be rewritten as `...`'

    def visit_tag(node)
      return unless tag_has_inline_script?(node) && inline_content_is_string?(node)

      plain = safe_plain_text(node.script)
      corrected = plain ? correct_tag(node, plain) : false
      record_lint(node, MESSAGE, corrected: corrected)
    end

    def visit_script(node)
      # Some script nodes created by the Haml parser aren't actually script
      # nodes declared via the `=` marker. Check for it.
      return unless /\A\s*=/.match?(node.source_code)
      return unless plain = safe_plain_text(node.script)

      record_lint(node, MESSAGE, corrected: correct_script(node, plain))
    end

    private

    # Rewrites `%tag= "..."` as `%tag ...`, dropping the `=` marker and the
    # surrounding quotes.
    #
    # @return [Boolean] whether a correction was applied
    def correct_tag(node, plain)
      marker = node.inline_marker_source.rstrip
      # Only unwrap plain escaped output (`= "..."`); leave `!=`, `~`, and the
      # whitespace-removal markers (`<`/`>`) untouched, as they change rendering.
      return false unless /\A=\s*["']/.match?(marker)

      index = node.line - 1
      line = autocorrected_lines[index]
      return false unless line.rstrip.end_with?(marker)

      prefix = line.rstrip[0...(line.rstrip.length - marker.length)]
      correct_line(index, "#{prefix} #{plain}")
    end

    # Rewrites a standalone `= "..."` script as plain text, preserving the
    # node's indentation.
    #
    # @return [Boolean] whether a correction was applied
    def correct_script(node, plain)
      index = node.line - 1
      line = autocorrected_lines[index]
      indentation = line[/\A\s*/]
      correct_line(index, "#{indentation}#{plain}")
    end

    # Returns the Haml plain-text equivalent of a Ruby string literal script, or
    # +nil+ when the script is not a string literal that can be safely unwrapped
    # (i.e. unwrapping would change the rendered output).
    #
    # @return [String, nil]
    def safe_plain_text(script)
      return if script.include?("\n")
      return unless tree = parse_ruby(script)
      return unless %i[str dstr].include?(tree.type)
      return unless safely_unwrappable?(tree)

      plain_text_from(tree)
    rescue ::Parser::SyntaxError
      # Gracefully ignore syntax errors, as that's managed by a different linter
      nil
    end

    # Whether unwrapping the string literal into Haml plain text would preserve
    # the rendered output.
    #
    # @return [Boolean]
    def safely_unwrappable?(tree)
      !starts_with_reserved_character?(tree.children.first) &&
        !contains_escape_sequence?(tree) &&
        !contains_significant_whitespace?(tree)
    end

    # Reconstructs the Haml plain-text form of a string literal. Literal segments
    # keep their text (with any `#{` escaped so Haml won't interpolate it), while
    # interpolation segments are emitted verbatim in their `#{...}` form.
    #
    # @return [String]
    def plain_text_from(tree)
      string_segments(tree).map do |segment|
        if segment.type == :str
          segment.children.first.gsub('#{') { '\#{' }
        else
          segment.location.expression.source
        end
      end.join
    end

    # Returns whether a string starts with a character that would otherwise be
    # given special treatment, thus making enclosing it in a string necessary.
    def starts_with_reserved_character?(stringish)
      string = stringish.respond_to?(:children) ? stringish.children.first : stringish
      string =~ %r{\A\s*[/#-=%~]} if string.is_a?(String)
    end

    # The ordered segments of a string literal, including any interpolation.
    # A plain `str` node has no interpolation, so it is its own only segment.
    def string_segments(tree)
      tree.type == :dstr ? tree.children : [tree]
    end

    # Returns whether any literal portion of the string contains a backslash
    # escape (e.g. `\n`, `\t`, `\u202F`). Such escapes are interpreted inside
    # a Ruby string but would be emitted verbatim as Haml plain text, so the
    # `= "..."` form is not equivalent to the unwrapped plain text.
    def contains_escape_sequence?(tree)
      string_segments(tree).any? do |segment|
        segment.type == :str && segment.location.expression.source.include?('\\')
      end
    end

    # Returns whether the string begins or ends with whitespace. Haml strips
    # trailing whitespace from plain text (and leading whitespace denotes
    # indentation), so unwrapping such a string would change the output.
    def contains_significant_whitespace?(tree)
      segments = string_segments(tree)
      bounded_by_whitespace?(segments.first, /\A\s/) ||
        bounded_by_whitespace?(segments.last, /\s\z/)
    end

    def bounded_by_whitespace?(segment, pattern)
      segment.type == :str && segment.children.first.to_s.match?(pattern)
    end
  end
end
