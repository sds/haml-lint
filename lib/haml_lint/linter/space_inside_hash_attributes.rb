# frozen_string_literal: true

module HamlLint
  # Checks for spaces inside the braces of hash attributes
  # (e.g. `%tag{ lang: en }` vs `%tag{lang: en}`).
  class Linter::SpaceInsideHashAttributes < Linter
    include LinterRegistry

    supports_autocorrect(true)

    STYLE = {
      'no_space' => {
        start_regex: /\A\{[^ ]/,
        end_regex: /(?:^\s*\}|[^ ]\})\z/,
        start_message: 'Hash attribute should start with no space after the opening brace',
        end_message: 'Hash attribute should end with no space before the closing brace or be on its own line'
      },
      'space' => {
        start_regex: /\A\{(?: [^ ]|$)/,
        end_regex: /(?:^\s*\}|[^ ] \})\z/,
        start_message: 'Hash attribute should start with one space after the opening brace',
        end_message: 'Hash attribute should end with one space before the closing brace or be on its own line'
      }
    }.freeze

    def visit_tag(node)
      return unless node.hash_attributes?

      style_name = config['style'] == 'no_space' ? 'no_space' : 'space'
      style = STYLE[style_name]
      source = node.hash_attributes_source

      start_ok = source.match?(style[:start_regex])
      end_ok = source.match?(style[:end_regex])
      return if start_ok && end_ok

      corrected = correct_hash_spacing(node, source, style_name)
      record_lint(node, style[:start_message], corrected: corrected) unless start_ok
      record_lint(node, style[:end_message], corrected: corrected) unless end_ok
    end

    private

    # @return [Boolean]
    def correct_hash_spacing(node, source, style_name)
      return false unless source
      return false if source.include?("\n") # multi-line hash: detection-only

      index = node.line - 1
      line = autocorrected_lines[index]
      return false unless line.include?(source)

      fixed = corrected_hash_source(source, style_name)
      return false if fixed == source

      correct_line(index, line.sub(source) { fixed })
    end

    # @return [String]
    def corrected_hash_source(source, style_name)
      inner = source[1...-1].strip

      if style_name == 'no_space'
        "{#{inner}}"
      elsif inner.empty?
        '{ }'
      else
        "{ #{inner} }"
      end
    end
  end
end
