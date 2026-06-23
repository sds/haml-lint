# frozen_string_literal: true

module HamlLint
  # Checks for empty object references (e.g. `%div[]`).
  class Linter::EmptyObjectReference < Linter
    include LinterRegistry

    supports_autocorrect(true)

    def visit_tag(node)
      return unless node.object_reference? &&
                    node.object_reference_source.strip.empty?

      corrected = correct_object_reference(node)
      record_lint(node, 'Empty object reference should be removed', corrected: corrected)
    end

    private

    # @return [Boolean]
    def correct_object_reference(node)
      index = node.line - 1
      line = autocorrected_lines[index]
      # `static_attributes_source` is just the `.class`/`#id` part (e.g. `.foo`),
      # so the optional `%tag` group captures an explicit tag name when present.
      static = Regexp.escape(node.static_attributes_source)
      correct_line(index, line.sub(/\A(\s*(?:%[-:\w]+)?#{static})\[\s*\]/, '\1'))
    end
  end
end
