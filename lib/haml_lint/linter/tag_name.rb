# frozen_string_literal: true

module HamlLint
  # Checks for tag names with uppercase letters.
  class Linter::TagName < Linter
    include LinterRegistry

    supports_autocorrect(true)

    def visit_tag(node)
      tag = node.tag_name
      return unless /[A-Z]/.match?(tag)

      corrected = correct_tag_name(node, tag)
      record_lint(node, "`#{tag}` should be written in lowercase as `#{tag.downcase}`",
                  corrected: corrected)
    end

    private

    # @return [Boolean]
    def correct_tag_name(node, tag)
      index = node.line - 1
      line = autocorrected_lines[index]
      correct_line(index, line.sub(/(%)#{Regexp.escape(tag)}/, "\\1#{tag.downcase}"))
    end
  end
end
