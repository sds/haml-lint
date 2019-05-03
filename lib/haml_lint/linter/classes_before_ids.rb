# frozen_string_literal: true

module HamlLint
  # Checks that classes are listed before IDs in tags.
  class Linter::ClassesBeforeIds < Linter
    include LinterRegistry

    # Map of prefixes to the type of tag component
    TYPES_BY_PREFIX = {
      '.' => :class,
      '#' => :id,
    }.freeze

    MSG = '%s should be listed before %s (%s should precede %s)'

    def visit_tag(node)
      # Convert ".class#id" into [.class, #id] (preserving order)
      components = node.static_attributes_source.scan(/[.#][^.#]+/)

      first, second = attribute_prefix_order

      components.each_cons(2) do |current_val, next_val|
        next unless next_val.start_with?(first) &&
                    current_val.start_with?(second)

        failure_message = format(MSG, *(attribute_type_order + [next_val, current_val]))
        record_lint(node, failure_message)
        break
      end
    end

    private

    def attribute_prefix_order
      default = %w[. #]
      default.reverse! if ids_first?
      default
    end

    def attribute_type_order
      default = %w[Classes IDs]
      default.reverse! if ids_first?
      default
    end

    def enforced_style
      config.fetch('EnforcedStyle', 'class')
    end

    def ids_first?
      enforced_style == 'id'
    end
  end
end
