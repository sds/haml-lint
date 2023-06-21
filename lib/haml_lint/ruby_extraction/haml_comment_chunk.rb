# frozen_string_literal: true

module HamlLint::RubyExtraction
  # Chunk for haml comments. Lines like `  -# Some commenting!`.
  # Only deals with indentation while correcting, but can also be fused to a ScriptChunk.
  class HamlCommentChunk < BaseChunk
    def fuse(following_chunk)
      return unless following_chunk.is_a?(HamlCommentChunk)

      # We only merge consecutive comments
      # The main reason to want to at least merge those is
      # so that an empty comment doesn't get removed by rubocop by mistake
      return if @haml_line_index + 1 != following_chunk.haml_line_index

      HamlCommentChunk.new(node, @ruby_lines + following_chunk.ruby_lines, end_marker_indent: end_marker_indent)
    end

    def fuse_script_chunk(following_chunk)
      return if following_chunk.end_marker_indent.nil?
      return if following_chunk.must_start_chunk

      nb_blank_lines_between = following_chunk.haml_line_index - haml_line_index - nb_haml_lines
      blank_lines = nb_blank_lines_between > 0 ? [''] * nb_blank_lines_between : []
      new_lines = @ruby_lines + blank_lines + following_chunk.ruby_lines

      source_map_skips = @skip_line_indexes_in_source_map
      source_map_skips.concat(following_chunk.skip_line_indexes_in_source_map
                                .map { |i| i + @ruby_lines.size })

      ScriptChunk.new(node,
                      new_lines,
                      haml_line_index: haml_line_index,
                      skip_line_indexes_in_source_map: source_map_skips,
                      end_marker_indent: following_chunk.end_marker_indent,
                      previous_chunk: previous_chunk)
    end

    def transfer_correction_logic(_coordinator, to_ruby_lines, haml_lines)
      if to_ruby_lines.empty?
        haml_lines.slice!(@haml_line_index..haml_end_line_index)
        return
      end
      delta_indent = min_indent_of(to_ruby_lines) - min_indent_of(@ruby_lines)

      HamlLint::Utils.map_subset!(haml_lines, @haml_line_index..haml_end_line_index) do |l|
        HamlLint::Utils.indent(l, delta_indent)
      end
    end

    def min_indent_of(lines)
      lines.map { |l| l.index(/\S/) }.compact.min
    end
  end
end
