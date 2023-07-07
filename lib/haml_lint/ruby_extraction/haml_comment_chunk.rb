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
