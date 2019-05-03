# frozen_string_literal: true

module HamlLint
  # Checks for class attributes defined in tag attribute hash with static
  # values.
  #
  # For example, it will prefer this:
  #
  #   %tag.class-name
  #
  # ...over:
  #
  #   %tag{ class: 'class-name' }
  #
  # But will allow invalid class names for templating:
  #
  #   %tag{ class: '{{ template-var }}' }
  class Linter::ClassAttributeWithStaticValue < Linter
    include LinterRegistry

    STATIC_TYPES = %i[str sym].freeze

    VALID_CLASS_REGEX = /^-?[_a-zA-Z]+[_a-zA-Z0-9-]*$/

    def visit_tag(node)
      return unless contains_class_attribute?(node.dynamic_attributes_sources)

      record_lint(node, 'Avoid defining `class` in attributes hash ' \
                        'for static class names')
    end

    private

    def surrounded_by_braces?(code)
      code.start_with?('{') && code.end_with?('}')
    end

    def contains_class_attribute?(attributes_sources)
      attributes_sources.each do |code|
        ast_root = parse_ruby(surrounded_by_braces?(code) ? code : "{#{code}}")
        next unless ast_root # RuboCop linter will report syntax errors

        ast_root.children.each do |pair|
          return true if static_class_attribute_value?(pair)
        end
      end

      false
    end

    def static_class_attribute_value?(pair)
      return false if (children = pair.children).empty?

      key, value = children

      STATIC_TYPES.include?(key.type) &&
        key.children.first.to_sym == :class &&
        STATIC_TYPES.include?(value.type) &&
        value.children.first =~ VALID_CLASS_REGEX
    end
  end
end
