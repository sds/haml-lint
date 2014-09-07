module HamlLint
  # Checks for Ruby comments that can be written as HAML comments.
  class Linter::RubyComments < Linter
    include LinterRegistry

    def visit_silent_script(node)
      if code_comment?(node)
        add_lint(node, 'Use `-#` for comments instead of `- #`')
      end
    end

  private

    def code_comment?(node)
      node.value[:text] =~ /\A\s+#/
    end
  end
end
