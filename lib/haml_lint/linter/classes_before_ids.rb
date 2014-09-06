module HamlLint
  # Checks that classes are listed before IDs in tags.
  class Linter::ClassesBeforeIds < Linter
    include LinterRegistry

    # Map of prefixes to the type of tag component
    TYPES_BY_PREFIX = {
      '%' => :tag,
      '.' => :class,
      '#' => :id,
    }

    def visit_tag(node)
      # Convert %tag.class#id into [%tag, .class, #id] (preserving order)
      components = tag_definition(node).scan(/[%.#][^%.#]+/)

      component_types = components.map { |comp| [TYPES_BY_PREFIX[comp[0]], comp] }

      # Check each pair component to the next to see if one is out of order
      component_types[0..-2].zip(component_types[1..-1]).each do |(a_type, a), (b_type, b)|
        next unless a_type == :id && b_type == :class

        add_lint(node, 'Classes should be listed before IDs '\
                       "(#{b} should precede #{a})")
        break
      end
    end
  end
end
