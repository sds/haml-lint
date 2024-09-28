# frozen_string_literal: true

require_relative 'null_node'

module HamlLint::Tree
  # Represents the root node of a HAML document that contains all other nodes.
  class RootNode < Node
    # The name of the file parsed to build this tree.
    #
    # @return [String] a file name
    def file
      @document.file
    end

    # Gets the node of the syntax tree for a given line number.
    #
    # @param line [Integer] the line number of the node
    # @return [HamlLint::Node]
    def node_for_line(line) # rubocop:disable Metrics
      each do |node|
        return node if node.line_numbers.cover?(line) && node != self
      end

      # Because HAML doesn't leave any trace in the nodes when it merges lines that
      # end with a comma, it's harder to assign a node to the second line here:
      # = some_call user,
      #             foo, bar
      # So if the simple strategy (above) doesn't work, we try to see if we check if the last node
      # that was before the requested line was one that could have been merged. If so, we use that one.
      best_guess = nil
      each do |node|
        best_guess = node if node != self && node.line_numbers.end < line
      end

      # There are the cases were the merging without traces can happen
      return best_guess if best_guess && %i[script silent_script tag].include?(best_guess.type)

      HamlLint::Tree::NullNode.new
    end
  end
end
