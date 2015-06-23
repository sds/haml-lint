module HamlLint
  # Checks that indentation doesn't use tabs
  class Linter::SpacesForIndentation < Linter
    include LinterRegistry

    def visit_root(_node)
      dummy_node = Struct.new(:line)

      document.source_lines.each_with_index do |line, index|
        next unless line =~ /^\s*\t/

        record_lint dummy_node.new(index + 1), 'Line contains tabs in indentation'
      end
    end
  end
end
