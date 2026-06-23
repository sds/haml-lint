# frozen_string_literal: true

module HamlLint
  # Checks for multiple lines of code comments that can be condensed.
  class Linter::ConsecutiveComments < Linter
    include LinterRegistry

    supports_autocorrect(true)
    autocorrect_safe(false)

    COMMENT_DETECTOR = ->(child) { child.type == :haml_comment }

    def visit_haml_comment(node)
      return if previously_reported?(node)

      HamlLint::Utils.for_consecutive_items(
        possible_group(node),
        COMMENT_DETECTOR,
        config['max_consecutive'] + 1,
      ) do |group|
        group.each { |group_node| reported_nodes << group_node }
        corrected = correct_group(group)
        record_lint(group.first,
                    "#{group.count} consecutive comments can be merged into one",
                    corrected: corrected)
      end
    end

    private

    # @return [Boolean]
    def correct_group(group)
      first_index = group.first.line - 1
      continuation_indent = "#{autocorrected_lines[first_index][/\A\s*/]}   "

      changed = false
      group[1..].each do |group_node|
        index = group_node.line - 1
        line = autocorrected_lines[index]
        changed = true if correct_line(index, continuation_indent + line.sub(/\A\s*-#\s?/, ''))
      end
      changed
    end

    def possible_group(node)
      node.subsequents.unshift(node)
    end

    def previously_reported?(node)
      reported_nodes.include?(node)
    end

    def reported_nodes
      @reported_nodes ||= []
    end
  end
end
