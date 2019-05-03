# frozen_string_literal: true

module HamlLint
  # Determines what linters are enabled or disabled via comments.
  class CommentConfiguration
    # Instantiates a new {HamlLint::CommentConfiguration}.
    #
    # @param node [HamlLint::Tree::Node] the node to configure
    def initialize(node)
      @directives = node.directives.reverse
    end

    # Checks whether a linter is disabled for the node.
    #
    # @api public
    # @param linter_name [String] the name of the linter
    # @return [true, false]
    def disabled?(linter_name)
      most_recent_disabled = directives_for(linter_name).map(&:disable?).first

      most_recent_disabled || false
    end

    private

    # The list of directives in order of precedence.
    #
    # @api private
    # @return [Array<HamlLint::Directive>]
    attr_reader :directives

    # Finds all directives applicable to the given linter name.
    #
    # @api private
    # @param linter_name [String] the name of the linter
    # @return [Array<HamlLint::Directive>] the filtered directives
    def directives_for(linter_name)
      directives.select { |directive| (directive.linters & ['all', linter_name]).any? }
    end
  end
end
