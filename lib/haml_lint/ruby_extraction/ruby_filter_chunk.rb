# frozen_string_literal: true

module HamlLint::RubyExtraction
  # Chunk for dealing with `:ruby` filter.
  class RubyFilterChunk < BaseChunk
    attr_reader :start_marker_indent

    def initialize(*args, start_marker_indent:, **kwargs)
      super(*args, **kwargs)
      @start_marker_indent = start_marker_indent
    end

    def transfer_correction_logic(coordinator, to_ruby_lines, haml_lines)
      marker_index = coordinator.find_line_index_of_marker_in_corrections(@start_marker_line_number)

      new_name_indent = coordinator.corrected_ruby_lines[marker_index].index(/\S/)

      delta_indent = new_name_indent - @start_marker_indent
      haml_lines[@haml_line_index - 1] = HamlLint::Utils.indent(haml_lines[@haml_line_index - 1], delta_indent)

      to_haml_lines = to_ruby_lines.map do |line|
        if !/\S/.match?(line)
          # whitespace or empty
          ''
        else
          "  #{line}"
        end
      end

      haml_lines[@haml_line_index..haml_end_line_index] = to_haml_lines
    end
  end
end
