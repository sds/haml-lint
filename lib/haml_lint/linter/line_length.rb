# frozen_string_literal: true

module HamlLint
  # Checks for lines longer than a maximum number of columns.
  class Linter::LineLength < Linter
    include LinterRegistry

    # A marker for a line within a multiline node.
    #
    # @api private
    DummyNode = Struct.new(:line)

    MSG = 'Line is too long. [%d/%d]'

    def visit_root(root)
      max_length = config['max']

      document.source_lines.each_with_index do |line, index|
        next if line.length <= max_length

        node = root.node_for_line(index + 1)
        unless node.disabled?(self)
          record_lint(DummyNode.new(index + 1), format(MSG, line.length, max_length))
        end
      end
    end
  end
end
