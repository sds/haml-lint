# frozen_string_literal: true

module HamlLint
  # Checks for the setting of attributes via HTML shorthand syntax on elements
  # (e.g. `%tag(lang=en)`).
  class Linter::HtmlAttributes < Linter
    include LinterRegistry

    supports_autocorrect(true)
    autocorrect_safe(false)

    MESSAGE = "Prefer the hash attributes syntax (%tag{ lang: 'en' }) " \
              'over HTML attributes syntax (%tag(lang=en))'

    def visit_tag(node)
      return unless node.html_attributes?

      record_lint(node, MESSAGE, corrected: correct(node))
    end

    private

    # Rewrites the HTML attribute group `(...)` as a Ruby hash group `{...}`,
    # preserving each attribute's value (static strings, booleans, and Ruby
    # expressions alike).
    #
    # The conversion is skipped (the lint is still reported) when it can't be
    # performed losslessly: when the tag already has a `{...}` hash group, when
    # the `.class`/`#id` shorthand is present (its `class`/`id` are merged into
    # the parsed attributes and can't be told apart from the HTML ones), or when
    # the attribute list spans multiple lines.
    #
    # @return [Boolean] whether a correction was applied
    def correct(node)
      return false unless correctable?(node)
      return false unless pairs = hash_pairs(node)

      hash_source = "{ #{pairs.join(', ')} }"
      return false unless parse_ruby(hash_source)

      index = node.line - 1
      line = autocorrected_lines[index]
      html_source = node.dynamic_attributes_source[:html]
      return false unless line.include?(html_source)

      correct_line(index, line.sub(html_source) { hash_source })
    end

    # Whether the tag's HTML attributes can be losslessly converted in place.
    #
    # @return [Boolean]
    def correctable?(node)
      return false if node.hash_attributes?
      return false unless node.static_attributes_source.empty?

      html_source = node.dynamic_attributes_source[:html]
      !html_source.nil? && !html_source.include?("\n")
    end

    # Builds the `key => value` fragments for the tag's HTML attributes, or +nil+
    # when one of the static values can't be safely serialized.
    #
    # @return [Array<String>, nil]
    def hash_pairs(node)
      pairs = node.static_attributes.map do |key, value|
        return nil unless serializable?(value)

        "#{key.inspect} => #{value.inspect}"
      end

      node.dynamic_attributes_sources.each do |literal|
        inner = literal.strip.delete_prefix('{').delete_suffix('}').sub(/,\s*\z/, '').strip
        pairs << inner unless inner.empty?
      end

      pairs
    end

    # @return [Boolean] whether the static attribute value round-trips through
    #   +#inspect+ as a Ruby literal
    def serializable?(value)
      value.is_a?(String) || [true, false, nil].include?(value) || value.is_a?(Numeric)
    end
  end
end
