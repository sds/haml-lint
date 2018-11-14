module HamlLint
  # Detects overly long views.
  class Linter::ViewLength < Linter
    include LinterRegistry

    MSG = 'View template is too long [%d/%d]'.freeze

    DummyNode = Struct.new(:line)

    def visit_root(root)
      max = config['max']
      line_count = document.source_lines.count
      node = root.children.first

      if line_count > max && !node.disabled?(self)
        record_lint(DummyNode.new(0), format(MSG, line_count, max))
      end
    end
  end
end
