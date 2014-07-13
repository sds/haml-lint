module HamlLint
  # Checks for tag names with uppercase letters.
  class Linter::TagName < Linter
    include LinterRegistry

    def visit_tag(node)
      tag = node.value[:name]
      return unless tag.match(/[A-Z]/)

      add_lint(node, "`#{tag}` should be written in lowercase as `#{tag.downcase}`")
    end
  end
end
