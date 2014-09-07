module HamlLint
  # Checks for empty scripts.
  class Linter::EmptyScript < Linter
    include LinterRegistry

    def visit_silent_script(node)
      return unless node.value[:text] =~ /\A\s*\Z/

      add_lint(node, 'Empty script should be removed')
    end
  end
end
