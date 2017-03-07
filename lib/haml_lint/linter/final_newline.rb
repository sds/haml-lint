module HamlLint
  # Checks for final newlines at the end of a file.
  class Linter::FinalNewline < Linter
    include LinterRegistry

    def visit_root(root)
      return if document.source.empty?

      node = root.node_for_line(document.source_lines.count)
      return if node.disabled?(self)

      ends_with_newline = document.source.end_with?("\n")

      if config['present']
        unless ends_with_newline
          record_lint(node, 'Files should end with a trailing newline')
        end
      elsif ends_with_newline
        record_lint(node, 'Files should not end with a trailing newline')
      end
    end
  end
end
