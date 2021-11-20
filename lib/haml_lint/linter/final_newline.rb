# frozen_string_literal: true

module HamlLint
  # Checks for final newlines at the end of a file.
  class Linter::FinalNewline < Linter
    include LinterRegistry

    def visit_root(root)
      return if document.source.empty?
      line_number = document.last_non_empty_line

      node = root.node_for_line(line_number)
      return if node.disabled?(self)

      ends_with_newline = document.source.end_with?("\n")

      if config['present']
        unless ends_with_newline
          record_lint(line_number, 'Files should end with a trailing newline')
        end
      elsif ends_with_newline
        record_lint(line_number, 'Files should not end with a trailing newline')
      end
    end
  end
end
