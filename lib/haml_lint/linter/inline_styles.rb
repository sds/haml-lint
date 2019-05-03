# frozen_string_literal: true

module HamlLint
  # Detects use of inline `style` attributes on any tag
  class Linter::InlineStyles < Linter
    include LinterRegistry

    MESSAGE = 'Do not use inline style attributes'

    def visit_tag(node)
      if node.has_hash_attribute?(:style)
        record_lint(node, MESSAGE)
      end
    end
  end
end
