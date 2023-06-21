# frozen_string_literal: true

module HamlLint::RubyExtraction
  # Chunk for handling outputting scripts after a tag, such as `%div= spam`
  class TagScriptChunk < BaseChunk
    def transfer_correction_logic(coordinator, to_ruby_lines, haml_lines) # rubocop:disable Metrics/AbcSize
      # TODO: add checks that we have commas at the end of each line except the last one

      from_ruby_line = @ruby_lines.first
      to_ruby_line = to_ruby_lines.first

      to_line_indent = to_ruby_line.index(/\S/)

      from_ruby_line = from_ruby_line.sub(coordinator.script_output_prefix, '').sub(/^\s+/, '')
      to_ruby_line = to_ruby_line.sub(coordinator.script_output_prefix, '').sub(/^\s+/, '')

      affected_start_index = haml_lines[@haml_line_index].rindex(from_ruby_line)

      haml_lines[@haml_line_index][affected_start_index..-1] = to_ruby_line

      indent_delta = affected_start_index - coordinator.script_output_prefix.size - to_line_indent

      HamlLint::Utils.map_after_first!(to_ruby_lines) do |line|
        HamlLint::Utils.indent(line, indent_delta)
      end

      haml_lines[(@haml_line_index + 1)..haml_end_line_index] = to_ruby_lines[1..]
    end
  end
end
