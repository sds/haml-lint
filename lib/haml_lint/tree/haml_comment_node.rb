require 'haml_lint/directive'

module HamlLint::Tree
  # Represents a HAML comment node.
  class HamlCommentNode < Node
    def directives
      directives = super
      directives << contained_directives
      directives.flatten
    end

    # Returns the full text content of this comment, including newlines if a
    # single comment spans multiple lines.
    #
    # @return [String]
    def text
      content = source_code
      indent = content[/^ */]

      content.gsub(/^#{indent}/, '')
             .gsub(/^-#/, '')
             .gsub(/^  /, '')
             .rstrip
    end

    private

    def contained_directives
      text
        .split("\n")
        .each_with_index
        .map { |source, offset| HamlLint::Directive.from_line(source, line + offset) }
        .reject { |directive| directive.is_a?(HamlLint::Directive::Null) }
    end
  end
end
