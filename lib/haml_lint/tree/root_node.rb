require 'haml_lint/tree/null_node'

module HamlLint::Tree
  # Represents the root node of a HAML document that contains all other nodes.
  class RootNode < Node
    # The name fo the file parsed to build this tree.
    #
    # @return [String] a file name
    def file
      @document.file
    end

    # Gets the node of the syntax tree for a given line number.
    #
    # @param line [Integer] the line number of the node
    # @return [HamlLint::Node]
    def node_for_line(line)
      find(-> { HamlLint::Tree::NullNode.new }) { |node| node.line_numbers.cover?(line) }
    end
  end
end
