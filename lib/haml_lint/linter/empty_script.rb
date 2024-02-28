# frozen_string_literal: true

module HamlLint
  # Checks for empty scripts.
  class Linter::EmptyScript < Linter
    include LinterRegistry

    def visit_silent_script(node)
      return unless /\A\s*\Z/.match?(node.script)

      record_lint(node, 'Empty script should be removed')
    end
  end
end
