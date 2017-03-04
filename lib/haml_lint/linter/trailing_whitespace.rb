module HamlLint
  # Checks for trailing whitespace.
  class Linter::TrailingWhitespace < Linter
    include LinterRegistry

    def visit_root(root)
      document.source_lines.each_with_index do |line, index|
        next unless line =~ /\s+$/

        node = root.node_for_line(index + 1)
        unless node.disabled?(self)
          record_lint node, 'Line contains trailing whitespace'
        end
      end
    end
  end
end
