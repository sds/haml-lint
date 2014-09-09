module HamlLint
  # Checks for uses of the multiline pipe character.
  class Linter::MultilinePipe < Linter
    include LinterRegistry

    def visit_tag(node)
      check(node)
    end

    def visit_script(node)
      check(node)
    end

    def visit_silent_script(node)
      check(node)
    end

    def visit_plain(node)
      line = line_text_for_node(node)

      # Plain text nodes are allowed to consist of a single pipe
      return if line.strip == '|'

      add_lint(node) if line.match(MULTILINE_PIPE_REGEX)
    end

    def message
      "Don't use the `|` character to split up lines. " \
      'Wrap on comma or extract code into helper.'
    end

    private

    MULTILINE_PIPE_REGEX = /\s+\|\s*$/

    def line_text_for_node(node)
      parser.lines[node.line - 1]
    end

    def check(node)
      line = line_text_for_node(node)
      add_lint(node) if line.match(MULTILINE_PIPE_REGEX)
    end
  end
end
