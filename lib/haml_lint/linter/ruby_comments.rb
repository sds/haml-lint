# frozen_string_literal: true

module HamlLint
  # Checks for Ruby comments that can be written as Haml comments.
  class Linter::RubyComments < Linter
    include LinterRegistry

    supports_autocorrect(true)

    def visit_silent_script(node)
      return unless code_comment?(node)

      corrected = correct_comment(node)
      record_lint(node, 'Use `-#` for comments instead of `- #`', corrected: corrected)
    end

    private

    def code_comment?(node)
      node.script =~ /\A\s+#/
    end

    # @return [Boolean]
    def correct_comment(node)
      index = node.line - 1
      line = autocorrected_lines[index]
      correct_line(index, line.sub(/\A(\s*)-\s+#/, '\1-#'))
    end
  end
end
