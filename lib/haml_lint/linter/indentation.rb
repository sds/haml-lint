module HamlLint
  # Checks the character used for indentation.
  class Linter::Indentation < Linter
    include LinterRegistry

    # Allowed leading indentation for each character type.
    INDENT_REGEX = {
      space: /^[ ]*(?!\t)/,
      tab: /^\t*(?![ ])/,
    }.freeze

    LEADING_SPACES_REGEX = /^( +)(?! )/

    def visit_root(root)
      character = config['character'].to_sym
      check_character(character, root)

      width = config['width'].to_i
      check_width(width, root) if character == :space && width > 0
    end

    private

    # validate that indentation matches config characters (either spaces or tabs)
    def check_character(character, root)
      wrong_characters = character == :space ? 'tabs' : 'spaces'
      regex = INDENT_REGEX[character]
      dummy_node = Struct.new(:line)

      document.source_lines.each_with_index do |line, index|
        next if line =~ regex

        unless root.node_for_line(index).disabled?(self)
          record_lint dummy_node.new(index + 1), "Line contains #{wrong_characters} in indentation"
        end
      end
    end

    # validate that indentation matches config width (only for spaces)
    def check_width(width, root)
      dummy_node = Struct.new(:line)

      # to avoid excessive noise, only check children of top level nodes
      # if indentation is proper below that, then `haml` will warn about inconsistent indentation
      root.children.each do |top_node|
        top_node.children.each do |node|
          line = node.source_code
          match = LEADING_SPACES_REGEX.match(line)

          if match && match[1] != ' ' * width && !node.disabled?(self)
            record_lint dummy_node.new(node.line), "Line is not indented #{width} spaces"
          end
        end
      end
    end
  end
end
