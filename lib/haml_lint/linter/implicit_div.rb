# frozen_string_literal: true

module HamlLint
  # Checks for unnecessary uses of the `%div` prefix where a class name or ID
  # already implies a div.
  class Linter::ImplicitDiv < Linter
    include LinterRegistry

    supports_autocorrect(true)

    def visit_tag(node)
      return unless node.tag_name == 'div'

      return unless node.static_classes.any? || node.static_ids.any?

      tag = node.source_code[/\s*([^\s={(\[]+)/, 1]
      return unless tag.start_with?('%div')

      corrected = correct_implicit_div(node)
      record_lint(node,
                  "`#{tag}` can be written as `#{node.static_attributes_source}` " \
                  'since `%div` is implicit',
                  corrected: corrected)
    end

    private

    # @return [Boolean]
    def correct_implicit_div(node)
      index = node.line - 1
      line = autocorrected_lines[index]
      correct_line(index, line.sub(/\A(\s*)%div(?=[.#])/, '\1'))
    end
  end
end
