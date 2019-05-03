# frozen_string_literal: true

module HamlLint
  # Checks for multiple consecutive silent script markers that could be
  # condensed into a :ruby filter block.
  class Linter::ConsecutiveSilentScripts < Linter
    include LinterRegistry

    SILENT_SCRIPT_DETECTOR = ->(child) do
      child.type == :silent_script && child.children.empty?
    end

    def visit_silent_script(node)
      return if previously_reported?(node)

      HamlLint::Utils.for_consecutive_items(
        possible_group(node),
        SILENT_SCRIPT_DETECTOR,
        config['max_consecutive'] + 1,
      ) do |group|
        record_lint(group.first,
                    "#{group.count} consecutive Ruby scripts can be merged " \
                    'into a single `:ruby` filter')
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
