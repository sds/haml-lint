module HamlLint::Tree
  # Represents a HAML comment node.
  class HamlCommentNode < Node
    # Returns the full text content of this comment, including newlines if a
    # single comment spans multiple lines.
    #
    # @return [String]
    def text
      last_possible_line =
        if next_node = successor
          next_node.line - 1
        else
          @parser.lines.count - 1
        end

      content = first_line_source.gsub(/\s*-#/, '')
      (line...last_possible_line).each do |line_number|
        # We strip all leading whitespace since the HAML parser won't allow
        # uneven amount of whitespace between subsequent comment lines
        line_content = @parser.lines[line_number].gsub(/\s*/, '')
        content += "\n#{line_content}"
      end

      # Strip trailing whitespace since it doesn't add value to the comment
      content.rstrip
    end
  end
end
