# frozen_string_literal: true

module HamlLint
  # Checks for the presence of instance variables
  class Linter::InstanceVariables < Linter
    include LinterRegistry

    # Enables the linter if the tree is for the right file type.
    #
    # @param [HamlLint::Tree::RootNode] the root of a syntax tree
    # @return [true, false] whether the linter is enabled for the tree
    def visit_root(node)
      @enabled = matcher.match(File.basename(node.file)) ? true : false
    end

    # Checks for instance variables in script nodes when the linter is enabled.
    #
    # @param [HamlLint::Tree:ScriptNode]
    # @return [void]
    def visit_script(node)
      return unless enabled?

      if node.parsed_script.contains_instance_variables?
        record_lint(node, "Avoid using instance variables in #{file_types} views")
      end
    end

    # @!method visit_silent_script(node)
    #   Checks for instance variables in script nodes when the linter is enabled.
    #
    #   @param [HamlLint::Tree:SilentScriptNode]
    #   @return [void]
    alias visit_silent_script visit_script

    # Checks for instance variables in tag nodes when the linter is enabled.
    #
    # @param [HamlLint::Tree:TagNode]
    # @return [void]
    def visit_tag(node)
      return unless enabled?

      visit_script(node) ||
        if node.parsed_attributes.contains_instance_variables?
          record_lint(node, "Avoid using instance variables in #{file_types} views")
        end
    end

    private

    # Tracks whether the linter is enabled for the file.
    #
    # @api private
    # @return [true, false]
    attr_reader :enabled

    # @!method enabled?
    #   Checks whether the linter is enabled for the file.
    #
    #   @api private
    #   @return [true, false]
    alias enabled? enabled

    # The type of files the linter is configured to check.
    #
    # @api private
    # @return [String]
    def file_types
      @file_types ||= config['file_types'] || 'partial'
    end

    # The matcher to use for testing whether to check a file by file name.
    #
    # @api private
    # @return [Regexp]
    def matcher
      @matcher ||= Regexp.new(config['matchers'][file_types] || '\A_.*\.haml\z')
    end
  end
end
