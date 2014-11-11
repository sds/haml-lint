module HamlLint
  # Checks for trailing whitespace.
  class Linter::TrailingWhitespace < Linter
    include LinterRegistry

    def visit_root(_node)
      dummy_node = Struct.new(:line)

      parser.lines.each_with_index do |line, index|
        next unless line =~ /\s+$/

        add_lint dummy_node.new(index + 1), 'Line contains trailing whitespace'
      end
    end
  end
end
