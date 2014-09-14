module HamlLint
  # Checks for unnecessary uses of string interpolation.
  #
  # For example, the following two code snippets are equivalent, but the latter
  # is more concise (and thus preferred):
  #
  #   %tag #{expression}
  #   %tag= expression
  class Linter::UnnecessaryInterpolation < Linter
    include LinterRegistry

    def visit_tag(node)
      inline_content = node.script
      return if inline_content.empty?

      if contains_interpolation?(inline_content) &&
         only_interpolation?(inline_content)
        add_lint(node, '`%... \#{expression}` can be written without ' \
                       'interpolation as `%...= expression`')
      end
    end

    private

    def only_interpolation?(content)
      content.lstrip.start_with?('"#{')
    end
  end
end
