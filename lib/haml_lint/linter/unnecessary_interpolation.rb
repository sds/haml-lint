# frozen_string_literal: true

module HamlLint
  # Checks for unnecessary uses of string interpolation.
  #
  # For example, the following two code snippets are equivalent, but the latter
  # is more concise (and thus preferred):
  #
  #   %tag #{expression}
  #   %tag= expression
  class Linter::UnnecessaryInterpolation < Linter
    include LinterRegistry

    supports_autocorrect(true)

    def visit_tag(node)
      return if node.script.length <= 2

      count = 0
      chars = 2 # Include surrounding quote chars
      interpolated_code = nil
      HamlLint::Utils.extract_interpolated_values(node.script) do |code, _line|
        count += 1
        return if count > 1 # rubocop:disable Lint/NonLocalExitFromIterator
        chars += code.length + 3
        interpolated_code = code
      end

      if chars == node.script.length
        corrected = correct_interpolation(node, interpolated_code)
        record_lint(node, '`%... \#{expression}` can be written without ' \
                          'interpolation as `%...= expression`', corrected: corrected)
      end
    end

    private

    # @return [Boolean]
    def correct_interpolation(node, interpolated_code)
      return false unless interpolated_code

      index = node.line - 1
      line = autocorrected_lines[index]
      escaped = Regexp.escape(interpolated_code)

      new_line =
        if inline_content_is_string?(node)
          line.sub(/=\s*"\#\{#{escaped}\}"\s*\z/, "= #{interpolated_code}")
        else
          line.sub(/\s+\#\{#{escaped}\}\s*\z/, "= #{interpolated_code}")
        end

      return false if new_line == line

      correct_line(index, new_line)
    end
  end
end
