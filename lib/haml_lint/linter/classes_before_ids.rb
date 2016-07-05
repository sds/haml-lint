module HamlLint
  # Checks that classes are listed before IDs in tags.
  class Linter::ClassesBeforeIds < Linter
    include LinterRegistry

    # Map of prefixes to the type of tag component
    TYPES_BY_PREFIX = {
      '.' => :class,
      '#' => :id,
    }.freeze

    def visit_tag(node)
      # Convert ".class#id" into [.class, #id] (preserving order)
      components = node.static_attributes_source.scan(/[.#][^.#]+/)

      first, second = attribute_prefix_order

      (1...components.count).each do |index|
        next unless components[index].start_with?(first) &&
                    components[index - 1].start_with?(second)

        record_lint(node, 'Classes should be listed before IDs '\
                          "(#{components[index]} should precede #{components[index - 1]})")
        break
      end
    end

    private

    def attribute_prefix_order
      enforced_style = config.fetch('EnforcedStyle', 'class')
      case enforced_style
      when 'id'
        ['#', '.']
      else
        ['.', '#']
      end
    end
  end
end
