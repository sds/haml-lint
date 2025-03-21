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

      # Rails technically allows the comment to be anywhere in the file,
      # but as a best practice they should be at the top of the file.
      # https://guides.rubyonrails.org/action_view_overview.html#strict-locals
      # https://github.com/rails/rails/blob/v8.0.2/actionview/lib/action_view/template.rb#L368
      found =
        root.children
            .take_while { |child| child.is_a?(HamlLint::Tree::HamlCommentNode) }
            .any?(&:is_strict_locals?)

      return if found

      record_lint(DummyNode.new(1), failure_message)
    end

    private

    # Checks whether the linter is enabled for the file.
    #
    # @api private
    # @return [true, false]
    def enabled?(root)
      return false unless matcher.match(File.basename(root.file))

      # This linter can also be disabled by a comment at the top of the file
      first_child = root.children.first
      first_child.nil? || !first_child.disabled?(self)
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
