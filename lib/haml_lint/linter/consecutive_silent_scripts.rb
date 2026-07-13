# frozen_string_literal: true

module HamlLint
  # Checks for multiple consecutive silent script markers that could be
  # condensed into a :ruby filter block.
  class Linter::ConsecutiveSilentScripts < Linter
    include LinterRegistry

    supports_autocorrect(true)
    autocorrect_safe(false)

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
        reported_nodes.concat(group)
        record_lint(group.first,
                    "#{group.count} consecutive Ruby scripts can be merged " \
                    'into a single `:ruby` filter',
                    corrected: collect_merge(group))
      end
    end

    def after_visit_root(_node)
      super
      return if merges.empty?

      apply_autocorrect(merged_source)
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

    def reset_autocorrect_state
      super
      @merges = []
    end

    # Queues a group of consecutive silent scripts to be replaced by an
    # equivalent `:ruby` filter block. Skips (and reports without correcting)
    # groups that aren't a run of single-line scripts on contiguous lines.
    #
    # @return [Boolean] whether a correction was queued
    def collect_merge(group)
      return false unless autocorrect?
      return false unless mergeable?(group)

      merges << {
        start: group.first.line - 1,
        finish: group.last.line - 1,
        lines: ruby_filter_lines(group),
      }
      true
    end

    # @return [Boolean] whether every script is a single line and the group
    #   occupies a contiguous run of lines
    def mergeable?(group)
      group.none? { |node| node.script.include?("\n") } &&
        group.each_cons(2).all? { |a, b| b.line == a.line + 1 }
    end

    # Builds the replacement lines: a `:ruby` filter marker at the group's
    # indentation, followed by each script's body indented one level deeper.
    #
    # @return [Array<String>]
    def ruby_filter_lines(group)
      indent = document.source_lines[group.first.line - 1][/\A\s*/]
      inner = indent + (indent.include?("\t") ? "\t" : '  ')
      ["#{indent}:ruby", *group.map { |node| "#{inner}#{node.script.strip}" }]
    end

    # Applies the queued range replacements from the bottom up (so earlier line
    # indices stay valid) and returns the rebuilt source.
    #
    # @return [String]
    def merged_source
      lines = document.source_lines.dup
      merges.sort_by { |merge| -merge[:start] }.each do |merge|
        lines[merge[:start]..merge[:finish]] = merge[:lines]
      end
      lines.join("\n")
    end

    def merges
      @merges ||= []
    end
  end
end
