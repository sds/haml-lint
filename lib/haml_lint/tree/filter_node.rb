# frozen_string_literal: true

module HamlLint::Tree
  # Represents a filter node which contains arbitrary code.
  class FilterNode < Node
    # The type of code contained in this filter.
    def filter_type
      @value[:name]
    end

    def text
      # Seems HAML strips the starting blank lines... without them, line numbers become offset,
      # breaking the source_map and auto-correct

      nb_blank_lines = 0
      nb_blank_lines += 1 while @document.source_lines[line + nb_blank_lines]&.empty?

      "#{"\n" * nb_blank_lines}#{super}"
    end

    # The line numbers that are contained within the node.
    #
    # Unlike most nodes, a filter's content begins on the line *after* the
    # `:filtername` declaration, so the span runs from the declaration line
    # through all of the indented content lines.
    #
    # @return [Range]
    def line_numbers
      return super if lines.empty?

      (line..(line + lines.count))
    end
  end
end
