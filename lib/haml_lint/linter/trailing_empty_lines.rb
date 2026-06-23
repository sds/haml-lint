# frozen_string_literal: true

module HamlLint
  # Checks for trailing empty lines.
  class Linter::TrailingEmptyLines < Linter
    include LinterRegistry

    supports_autocorrect(true)

    DummyNode = Struct.new(:line)

    def visit_root(root)
      return if document.source.empty?
      line_number = document.last_non_empty_line

      node = root.node_for_line(line_number)
      return if node.disabled?(self)

      return unless document.source.end_with?("\n\n")

      record_lint(line_number, 'Files should not end with trailing empty lines',
                  corrected: autocorrect?)

      apply_autocorrect(corrected_source)
    end

    private

    def corrected_source
      last_non_empty_index = document.source_lines.rindex { |line| !line.empty? } || 0
      "#{document.source_lines[0..last_non_empty_index].join("\n")}\n"
    end
  end
end
