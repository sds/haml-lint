# frozen_string_literal: true

module HamlLint::RubyExtraction
  # Chunk for dealing with every HAML filter other than `:ruby`
  # The generated Ruby for these is just a HEREDOC, so interpolation is corrected at
  # the same time by RuboCop.
  class NonRubyFilterChunk < BaseChunk
    def transfer_correction_logic(_coordinator, to_ruby_lines, haml_lines)
      delta_indent = to_ruby_lines.first.index(/\S/) - @ruby_lines.first.index(/\S/)

      haml_lines[@haml_line_index] = HamlLint::Utils.indent(haml_lines[@haml_line_index], delta_indent)

      # Ignoring the starting <<~HAML_LINT_FILTER and ending end
      to_content_lines = to_ruby_lines[1...-1]

      to_haml_lines = to_content_lines.map do |line|
        if !/\S/.match?(line)
          # whitespace or empty
          ''
        else
          line
        end
      end

      haml_lines[(@haml_line_index + 1)..haml_end_line_index] = to_haml_lines
    end

    def skip_line_indexes_in_source_map
      [@ruby_lines.size - 1]
    end
  end
end
