# frozen_string_literal: true

require 'delegate'

module HamlLint
  # A thin wrapper around the syntax tree from the Parser gem.
  class ParsedRuby < SimpleDelegator
    # !@method syntax_tree
    #   Returns the bare syntax tree from the wrapper.
    #
    #   @api semipublic
    #   @return [Array] syntax tree in the form returned by Parser gem
    alias syntax_tree __getobj__

    # Checks whether the syntax tree contains any instance variables.
    #
    # @return [true, false]
    def contains_instance_variables?
      return false unless syntax_tree

      syntax_tree.ivar_type? || syntax_tree.each_descendant.any?(&:ivar_type?)
    end
  end
end
