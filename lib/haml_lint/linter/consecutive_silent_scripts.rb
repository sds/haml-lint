module HamlLint
  # Checks for multiple consecutive silent script markers that could be
  # condensed into a :ruby filter block.
  class Linter::ConsecutiveSilentScripts < Linter
    include LinterRegistry

    SILENT_SCRIPT_DETECTOR = ->(child) do
      child.type == :silent_script && child.children.empty?
    end

    def visit_root(node)
      HamlLint::Utils.find_consecutive(
        node.children,
        config['max_consecutive'] + 1,
        SILENT_SCRIPT_DETECTOR,
      ) do |group|
        add_lint(group.first,
                 "#{group.count} consecutive Ruby scripts can be merged into " \
                 'a single `:ruby` filter')
      end
    end
  end
end
