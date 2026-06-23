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

    supports_autocorrect(true)

    STATIC_TYPES = %i[str sym].freeze

    VALID_CLASS_REGEX = /^-?[_a-zA-Z]+[_a-zA-Z0-9-]*$/

    def visit_tag(node)
      class_value = static_class_value(node.dynamic_attributes_sources)
      return unless class_value

      corrected = correct_class_attribute(node, class_value)
      record_lint(node, 'Avoid defining `class` in attributes hash ' \
                        'for static class names', corrected: corrected)
    end

    private

    def surrounded_by_braces?(code)
      code.start_with?('{') && code.end_with?('}')
    end

    # @return [String, nil]
    def static_class_value(attributes_sources)
      attributes_sources.each do |code|
        ast_root = parse_ruby(surrounded_by_braces?(code) ? code : "{#{code}}")
        next unless ast_root # RuboCop linter will report syntax errors

        ast_root.children.each do |pair|
          value = static_class_attribute_value(pair)
          return value if value
        end
      end

      nil
    end

    # @return [String, nil]
    def static_class_attribute_value(pair)
      return nil if (children = pair.children).empty?

      key, value = children

      return nil unless STATIC_TYPES.include?(key.type) &&
                        key.children.first.to_sym == :class &&
                        STATIC_TYPES.include?(value.type)

      class_name = value.children.first.to_s
      VALID_CLASS_REGEX.match?(class_name) ? class_name : nil
    end

    # @return [Boolean]
    def correct_class_attribute(node, class_value)
      hash_source = node.hash_attributes_source
      return false unless hash_source
      return false if hash_source.include?("\n")
      return false unless node.dynamic_attributes_source.keys == [:hash]
      return false unless sole_pair?(node.dynamic_attributes_sources)
      return false if node.static_classes.flatten.include?(class_value)

      index = node.line - 1
      line = autocorrected_lines[index]
      old = "#{node.static_attributes_source}#{hash_source}"
      return false unless line.include?(old)

      new = "#{node.static_attributes_source}.#{class_value}"
      correct_line(index, line.sub(old, new))
    end

    # Whether the attribute hash contains exactly one key/value pair (the class).
    #
    # @return [Boolean]
    def sole_pair?(attributes_sources)
      return false unless attributes_sources.size == 1

      code = attributes_sources.first
      ast_root = parse_ruby(surrounded_by_braces?(code) ? code : "{#{code}}")
      return false unless ast_root

      ast_root.children.size == 1
    end
  end
end
