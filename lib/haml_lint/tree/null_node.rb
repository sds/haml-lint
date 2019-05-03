# frozen_string_literal: true

module HamlLint::Tree
  # A null object version of a node that can be used as a safe default.
  class NullNode < Node
    # Instantiates a new {HamlLint::Tree::NullNode}, ignoring all input.
    def initialize(*_args); end

    # Overrides the disabled check to always say the linter is enabled.
    #
    # @param _linter [HamlLint::Linter] the linter to check
    # @return [false]
    def disabled?(_linter)
      false
    end
  end
end
