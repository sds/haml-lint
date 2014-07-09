module HamlLint
  class Linter::LineLength < Linter
    include LinterRegistry

    MSG = 'Line is too long. [%d/%d]'
    MAX = 79

    def visit(node)
      parser.lines.each_with_index do |line, index|
        if line.length > MAX
          node = Struct.new(:line)
          add_lint(node.new(index + 1), format(MSG, line.length, MAX))
        end
      end
    end
  end
end
