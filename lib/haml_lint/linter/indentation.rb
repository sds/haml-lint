# frozen_string_literal: true

module HamlLint
  # Checks the character used for indentation.
  class Linter::Indentation < Linter
    include LinterRegistry

    # Allowed leading indentation for each character type.
    INDENT_REGEX = {
      space: /^ *(?!\t)/,
      tab: /^\t*(?! )/,
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
        next if line&.match?(regex)

        unless root.node_for_line(index).disabled?(self)
          record_lint dummy_node.new(index + 1), "Line contains #{wrong_characters} in indentation"
        end
      end
    end

    # validate that indentation matches config width (only for spaces)
    def check_width(width, root)
      dummy_node = Struct.new(:line)

      root.children.each do |top_node|
        # once we've found one line with leading space, there's no need to check any more lines
        # `haml` will check indenting_at_start, deeper_indenting, inconsistent_indentation
        break if top_node.children.find do |node| # rubocop:disable Lint/UnreachableLoop
          line = node.source_code
          leading_space = LEADING_SPACES_REGEX.match(line)

          break unless leading_space && !node.disabled?(self)

          if leading_space[1] != ' ' * width
            record_lint dummy_node.new(node.line), "File does not use #{width}-space indentation"
          end

          break true
        end
      end
    end
  end
end
