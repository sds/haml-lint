module HamlLint
  # Checks for multiple consecutive silent script markers that could be
  # condensed into a :ruby filter block.
  class Linter::ConsecutiveSilentScripts < Linter
    include LinterRegistry

    SCRIPT_DETECTOR = ->(child) { child.type == :silent_script }

    def visit_root(node)
      HamlLint::Utils.find_consecutive(
        node.children,
        config['max_consecutive'] + 1,
        SCRIPT_DETECTOR,
      ) do |group|
        add_lint(group.first,
                 "#{group.count} consecutive Ruby scripts can be merged into " \
                 'a single `:ruby` filter')
      end
    end
  end
end
