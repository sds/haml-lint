# frozen_string_literal: true

module HamlLint
  # Checks for comments that don't have a leading space.
  class Linter::LeadingCommentSpace < Linter
    include LinterRegistry

    supports_autocorrect(true)

    def visit_haml_comment(node)
      # Skip if the node spans multiple lines starting on the second line,
      # or starts with a space
      return if /\A#*(\s*|\s+\S.*)$/.match?(node.text)

      corrected = correct_leading_space(node)
      record_lint(node, 'Comment should have a space after the `#`', corrected: corrected)
    end

    private

    # @return [Boolean]
    def correct_leading_space(node)
      index = node.line - 1
      line = autocorrected_lines[index]
      correct_line(index, line.sub(/\A(\s*-#+)(?=\S)/, '\1 '))
    end
  end
end
