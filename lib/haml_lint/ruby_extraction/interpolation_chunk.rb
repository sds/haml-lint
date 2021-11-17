# frozen_string_literal: true

module HamlLint::RubyExtraction
  # Deals with interpolation within a plain text, filter, etc.
  # Can only handling single line interpolation, so will be skipped if it takes
  # more than one line or if the correction takes more than one line.
  #
  # Stores the char index to know where in the line to do the replacements.
  class InterpolationChunk < BaseChunk
    def initialize(*args, start_char_index:, **kwargs)
      super(*args, **kwargs)
      @start_char_index = start_char_index
    end

    def transfer_correction_logic(coordinator, to_ruby_lines, haml_lines)
      return if @ruby_lines.size != 1
      return if to_ruby_lines.size != 1

      from_ruby_line = @ruby_lines.first.partition(coordinator.script_output_prefix).last
      to_ruby_line = to_ruby_lines.first.partition(coordinator.script_output_prefix).last

      haml_line = haml_lines[@haml_line_index]
      haml_line[@start_char_index...(@start_char_index + from_ruby_line.size)] = to_ruby_line
    end
  end
end
