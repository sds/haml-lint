module HamlLint
  # Checks for lines longer than a maximum number of columns.
  class Linter::LineLength < Linter
    include LinterRegistry

    MSG = 'Line is too long. [%d/%d]'

    def visit_root(node)
      max_length = config['max']

      parser.lines.each_with_index do |line, index|
        next if line.length <= max_length

        node = Struct.new(:line)
        add_lint(node.new(index + 1), format(MSG, line.length, max_length))
      end
    end
  end
end
