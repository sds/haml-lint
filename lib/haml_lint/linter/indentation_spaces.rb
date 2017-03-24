module HamlLint
  # Checks the number of spaces used for indentation.
  class Linter::IndentationSpaces < Linter
    include LinterRegistry

    TABS = /^\t+\b/

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
      check(node)
    end

    private

    def line_text_for_node(node)
      document.source_lines[node.line - 1]
    end

    def check(node)
      width = config['width'].to_i
      regex = /^(?: {#{width}})*(?!\s)/
      line = line_text_for_node(node)

      unless line =~ regex || line =~ TABS
        record_lint node, "Line does not use #{width}-space indentation"
      end
    end
  end
end
