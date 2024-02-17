# frozen_string_literal: true

module HamlLint
  # Checks for trailing whitespace.
  class Linter::TrailingWhitespace < Linter
    include LinterRegistry

    DummyNode = Struct.new(:line)

    def visit_root(root)
      document.source_lines.each_with_index do |line, index|
        next unless /\s+$/.match?(line)

        node = root.node_for_line(index + 1)
        unless node.disabled?(self)
          record_lint DummyNode.new(index + 1), 'Line contains trailing whitespace'
        end
      end
    end
  end
end
