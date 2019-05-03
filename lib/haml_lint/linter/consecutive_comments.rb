# frozen_string_literal: true

module HamlLint
  # Checks for multiple lines of code comments that can be condensed.
  class Linter::ConsecutiveComments < Linter
    include LinterRegistry

    COMMENT_DETECTOR = ->(child) { child.type == :haml_comment }

    def visit_haml_comment(node)
      return if previously_reported?(node)

      HamlLint::Utils.for_consecutive_items(
        possible_group(node),
        COMMENT_DETECTOR,
        config['max_consecutive'] + 1,
      ) do |group|
        group.each { |group_node| reported_nodes << group_node }
        record_lint(group.first,
                    "#{group.count} consecutive comments can be merged into one")
      end
    end

    private

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
