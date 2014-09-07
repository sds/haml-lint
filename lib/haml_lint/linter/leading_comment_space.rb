module HamlLint
  # Checks for comments that don't have a leading space.
  class Linter::LeadingCommentSpace < Linter
    include LinterRegistry

    def visit_haml_comment(node)
      return if node.value[:text][0] == ' '

      add_lint(node, 'Comment should have a space after the `#`')
    end
  end
end
