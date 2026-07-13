# frozen_string_literal: true

module HamlLint
  # Checks for tabs that are placed for alignment of tag content
  class Linter::AlignmentTabs < Linter
    include LinterRegistry

    supports_autocorrect(true)
    autocorrect_safe(false)

    REGEX = /[^\s*]\t+/
    # Same as +REGEX+, but captures the character preceding the alignment tabs
    # so it can be kept while the tabs themselves are collapsed to a space.
    CORRECTION_REGEX = /([^\s*])\t+/

    def visit_tag(node)
      return unless REGEX.match?(node.source_code)

      record_lint(node, 'Avoid using tabs for alignment', corrected: correct(node))
    end

    private

    # @return [Boolean] whether a correction was applied
    def correct(node)
      index = node.line - 1
      line = autocorrected_lines[index]
      correct_line(index, line.gsub(CORRECTION_REGEX) { "#{::Regexp.last_match(1)} " })
    end
  end
end
