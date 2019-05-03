# frozen_string_literal: true

module HamlLint
  # Checks for empty object references (e.g. `%div[]`).
  class Linter::EmptyObjectReference < Linter
    include LinterRegistry

    def visit_tag(node)
      return unless node.object_reference? &&
                    node.object_reference_source.strip.empty?

      record_lint(node, 'Empty object reference should be removed')
    end
  end
end
