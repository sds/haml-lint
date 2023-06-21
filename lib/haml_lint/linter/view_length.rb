# frozen_string_literal: true

module HamlLint
  # Detects overly long views.
  class Linter::ViewLength < Linter
    include LinterRegistry

    MSG = 'View template is too long [%d/%d]'

    DummyNode = Struct.new(:line)

    def visit_root(root)
      max = config['max']
      line_count = document.last_non_empty_line
      node = root.children.first

      if line_count > max && !node.disabled?(self)
        record_lint(DummyNode.new(0), format(MSG, line_count, max))
      end
    end
  end
end
