# frozen_string_literal: true

module HamlLint
  # Checks scripts spread over multiple lines.
  class Linter::MultilineScript < Linter
    include LinterRegistry

    supports_autocorrect(true)
    autocorrect_safe(false)

    # List of operators that can split a script into two lines that we want to
    # alert on.
    SPLIT_OPERATORS = %w[
      || or && and
      ||= &&=
      ^ << >> | &
      <<= >>= |= &=
      + - * / ** %
      += -= *= /= **= %=
      < <= <=> >= >
      = == === != =~ !~
      .. ...
      ? :
      not
      if unless while until
      begin
    ].to_set

    def visit_script(node)
      check(node)
    end

    def visit_silent_script(node)
      check(node)
    end

    def after_visit_root(node)
      super
      return if merges.empty?

      apply_autocorrect(merged_source)
    end

    private

    def reset_autocorrect_state
      super
      @merges = []
    end

    def merged_source
      lines = document.source_lines.dup
      to_delete = apply_merges(lines)
      lines.reject.with_index { |_, index| to_delete.include?(index) }.join("\n")
    end

    # Mutates +lines+ in place, folding each continuation script onto its chain
    # root, and returns the line indices that should be deleted.
    #
    # @return [Array<Integer>]
    def apply_merges(lines)
      redirect = {}
      merges.sort_by { |merge| merge[:from] }.map do |merge|
        root = redirect.fetch(merge[:from], merge[:from])
        redirect[merge[:succ_line]] = root
        lines[root] = "#{lines[root].rstrip} #{merge[:succ_script]}"
        merge[:succ_line]
      end
    end

    def check(node)
      # Condition occurs when scripts do not contain nested content, e.g.
      #
      #   - if condition ||      <-- no children; its sibling is a continuation
      #   -    other_condition
      #
      # ...whereas when it contains nested content it's not a multiline script:
      #
      #   - begin                <-- has children
      #     some_helper
      #   - rescue
      #     An error occurred
      return unless node.children.empty?

      operator = node.script[/\s+(\S+)\z/, 1]
      return unless SPLIT_OPERATORS.include?(operator)

      corrected = collect_merge(node)
      record_lint(node,
                  "Script with trailing operator `#{operator}` should be " \
                  'merged with the script on the following line',
                  corrected: corrected)
    end

    def collect_merge(node)
      return false unless autocorrect?

      # Only merge with the immediately following sibling on the next line.
      # `node.successor` would climb to an ancestor's sibling when this script is
      # the last child of its block, which would pull a line from outside the
      # block into it and change the semantics.
      succ = node.subsequents.first
      return false unless succ && %i[script silent_script].include?(succ.type)
      return false unless succ.line == node.line + 1

      merges << {
        from: node.line - 1,
        succ_line: succ.line - 1,
        succ_script: succ.script.strip,
      }
      true
    end

    def merges
      @merges ||= []
    end
  end
end
