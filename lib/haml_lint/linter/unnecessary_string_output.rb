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

    MESSAGE = '`= "..."` should be rewritten as `...`'

    def visit_tag(node)
      if tag_has_inline_script?(node) && inline_content_is_string?(node)
        record_lint(node, MESSAGE)
      end
    end

    def visit_script(node)
      # Some script nodes created by the Haml parser aren't actually script
      # nodes declared via the `=` marker. Check for it.
      return unless /\A\s*=/.match?(node.source_code)

      if outputs_string_literal?(node)
        record_lint(node, MESSAGE)
      end
    end

    private

    def outputs_string_literal?(script_node)
      return unless tree = parse_ruby(script_node.script)
      return unless %i[str dstr].include?(tree.type)

      !starts_with_reserved_character?(tree.children.first) &&
        !contains_escape_sequence?(tree) &&
        !contains_significant_whitespace?(tree)
    rescue ::Parser::SyntaxError
      # Gracefully ignore syntax errors, as that's managed by a different linter
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
