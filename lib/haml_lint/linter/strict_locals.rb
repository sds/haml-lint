# frozen_string_literal: true

module HamlLint
  # Checks for the presence of a `locals` magic comment at the beginning of a partial.
  class Linter::StrictLocals < Linter
    include LinterRegistry

    DummyNode = Struct.new(:line)

    # Enables the linter if the tree is for the right file type.
    #
    # @param [HamlLint::Tree::RootNode] the root of a syntax tree
    # @return [true, false] whether the linter is enabled for the tree
    def visit_root(root)
      return unless enabled?(root)

      first_child = root.children.first
      return if first_child.is_a?(HamlLint::Tree::HamlCommentNode) &&
                    first_child.is_strict_locals?

      # Check whether this linter is disabled by a comment
      return if first_child.disabled?(self)

      record_lint(DummyNode.new(1), failure_message)
    end

    private

    # Checks whether the linter is enabled for the file.
    #
    # @api private
    # @return [true, false]
    def enabled?(root)
      matcher.match(File.basename(root.file)) ? true : false
    end

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

    # The error message when an `locals` comment is not found.
    #
    # @api private
    # @return [String]
    def failure_message
      'Expected a strict `-# locals: ()` comment at the beginning of the file'
    end
  end
end
