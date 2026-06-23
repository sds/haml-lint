# frozen_string_literal: true

module HamlLint
  # Checks that classes are listed before IDs in tags.
  class Linter::ClassesBeforeIds < Linter
    include LinterRegistry

    supports_autocorrect(true)

    MSG = '%s should be listed before %s (%s should precede %s)'

    def visit_tag(node)
      # Convert ".class#id" into [.class, #id] (preserving order)
      components = node.static_attributes_source.scan(/[.#][^.#]+/)

      first, second = attribute_prefix_order

      components.each_cons(2) do |current_val, next_val|
        next unless next_val.start_with?(first) &&
                    current_val.start_with?(second)

        corrected = correct_attribute_order(node, components)
        failure_message = format(MSG, *(attribute_type_order + [next_val, current_val]))
        record_lint(node, failure_message, corrected: corrected)
        break
      end
    end

    private

    # @param node [HamlLint::Tree::TagNode]
    # @param components [Array<String>] the `.class`/`#id` components in source order
    # @return [Boolean]
    def correct_attribute_order(node, components)
      classes, ids = components.partition { |component| component.start_with?('.') }
      new_source = (ids_first? ? ids + classes : classes + ids).join

      index = node.line - 1
      line = autocorrected_lines[index]
      correct_line(index, line.sub(node.static_attributes_source, new_source))
    end

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
