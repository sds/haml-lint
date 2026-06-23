# frozen_string_literal: true

module HamlLint
  # Checks for trailing whitespace.
  class Linter::TrailingWhitespace < Linter
    include LinterRegistry

    supports_autocorrect(true)

    DummyNode = Struct.new(:line)

    def visit_root(root)
      new_lines = document.source_lines.dup
      changed = false

      document.source_lines.each_with_index do |line, index|
        next unless /\s+$/.match?(line)

        node = root.node_for_line(index + 1)
        next if node.disabled?(self)

        if autocorrect?
          new_lines[index] = line.sub(/\s+$/, '')
          changed = true
        end

        record_lint(DummyNode.new(index + 1), 'Line contains trailing whitespace',
                    corrected: autocorrect?)
      end

      apply_autocorrect(new_lines.join("\n")) if changed
    end
  end
end
