# frozen_string_literal: true

module HamlLint
  # Checks for tabs that are placed for alignment of tag content
  class Linter::AlignmentTabs < Linter
    REGEX = /[^\s*]\t+/

    def visit_tag(node)
      if REGEX.match?(node.source_code)
        record_lint(node, 'Avoid using tabs for alignment')
      end
    end
  end
end
