module HamlLint
  # Checks for multiple lines of code comments that can be condensed.
  class Linter::ConsecutiveComments < Linter
    include LinterRegistry

    MIN_CONSECUTIVE = 2
    COMMENT_DETECTOR = ->(child) { child.type == :haml_comment }

    def visit_root(node)
      HamlLint::Utils.find_consecutive(
        node.children,
        MIN_CONSECUTIVE,
        COMMENT_DETECTOR,
      ) do |group|
        add_lint(group.first,
                 "#{group.count} consecutive comments can be merged into one")

      end
    end
  end
end
