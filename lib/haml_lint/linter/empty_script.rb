# frozen_string_literal: true

module HamlLint
  # Checks for empty scripts.
  class Linter::EmptyScript < Linter
    include LinterRegistry

    supports_autocorrect(true)
    autocorrect_safe(false)

    def visit_silent_script(node)
      return unless /\A\s*\Z/.match?(node.script)

      # Only a childless `-` can be deleted; a `-` with children is degenerate
      # but is still reported.
      deletable = node.children.empty?
      deleted_lines << (node.line - 1) if autocorrect? && deletable
      record_lint(node, 'Empty script should be removed',
                  corrected: autocorrect? && deletable)
    end

    def after_visit_root(node)
      super
      return if deleted_lines.empty?

      kept = document.source_lines.reject.with_index do |_, index|
        deleted_lines.include?(index)
      end
      apply_autocorrect(kept.join("\n"))
    end

    private

    def reset_autocorrect_state
      super
      @deleted_lines = []
    end

    # @return [Array<Integer>]
    def deleted_lines
      @deleted_lines ||= []
    end
  end
end
