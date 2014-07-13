module HamlLint
  # Checks for unnecessary uses of the `%div` prefix where a class name or ID
  # already implies a div.
  class Linter::ImplicitDiv < Linter
    include LinterRegistry

    def visit_tag(node)
      return unless node.value[:name] == 'div'

      return unless node.value[:attributes]['class'] ||
                    node.value[:attributes]['id']

      tag = @parser.lines[node.line - 1][/\s*([^\s={\(\[]+)/, 1]
      return unless tag.start_with?('%div')

      add_lint(node, "`#{tag}` can be written as `#{tag[4..-1]}` since `%div` is implicit")
    end
  end
end
