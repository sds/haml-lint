module HamlLint
  # Checks the character used for indentation.
  class Linter::Indentation < Linter
    include LinterRegistry

    # Allowed leading indentation for each character type.
    INDENT_REGEX = {
      space: /^[ ]*(?!\t)/,
      tab: /^\t*(?![ ])/,
    }.freeze

    def visit_root(root)
      regex = INDENT_REGEX[config['character'].to_sym]
      dummy_node = Struct.new(:line)

      document.source_lines.each_with_index do |line, index|
        next if line =~ regex

        unless root.node_for_line(index).disabled?(self)
          record_lint dummy_node.new(index + 1), 'Line contains tabs in indentation'
        end
      end
    end
  end
end
