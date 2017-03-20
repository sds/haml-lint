module HamlLint
  # Checks the number of spaces used for indentation.
  class Linter::IndentationSpaces < Linter
    include LinterRegistry

    TABS = /^\t+\b/

    def visit_root(root)
      width = config['width'].to_i
      regex = /^(?: {#{width}})*(?!\s)/
      dummy_node = Struct.new(:line)

      document.source_lines.each_with_index do |line, index|
        next if line =~ regex || line =~ TABS

        unless root.node_for_line(index).disabled?(self)
          record_lint dummy_node.new(index + 1), "Line does not use #{width}-space indentation"
        end
      end
    end
  end
end
