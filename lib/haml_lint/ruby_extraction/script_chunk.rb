# frozen_string_literal: true

module HamlLint::RubyExtraction
  # Chunk for handling outputting and silent scripts, so `  = foo` and `  - bar`
  # Does NOT handle a script beside a tag (ex: `%div= spam`)
  class ScriptChunk < BaseChunk
    MID_BLOCK_KEYWORDS = %w[else elsif when rescue ensure].freeze

    # @return [Boolean] true if this ScriptChunk must be at the beginning of a chunk.
    #   This blocks this ScriptChunk from being fused to a ScriptChunk that is before it.
    #   Needed to handle some patterns of outputting script.
    attr_reader :must_start_chunk

    # @return [Array<Integer>] Line indexes to ignore when building the source_map. For examples,
    #   implicit `end` are on their own line in the Ruby file, but in the HAML, they are absent.
    attr_reader :skip_line_indexes_in_source_map

    # @return [HamlLint::RubyExtraction::BaseChunk] The previous chunk can affect how
    #   our starting marker must be indented.
    attr_reader :previous_chunk

    def initialize(*args, previous_chunk:, must_start_chunk: false,
                   skip_line_indexes_in_source_map: [], **kwargs)
      super(*args, **kwargs)
      @must_start_chunk = must_start_chunk
      @skip_line_indexes_in_source_map = skip_line_indexes_in_source_map
      @previous_chunk = previous_chunk
    end

    def fuse(following_chunk)
      case following_chunk
      when ScriptChunk
        fuse_script_chunk(following_chunk)
      when ImplicitEndChunk
        fuse_implicit_end(following_chunk)
      end
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

    def fuse_implicit_end(following_chunk)
      new_lines = @ruby_lines.dup
      last_non_empty_line_index = new_lines.rindex { |line| line =~ /\S/ }

      # There is only one line in ImplicitEndChunk
      new_end_index = last_non_empty_line_index + 1
      new_lines.insert(new_end_index, following_chunk.ruby_lines.first)
      source_map_skips = @skip_line_indexes_in_source_map + [new_end_index]

      ScriptChunk.new(node,
                      new_lines,
                      haml_line_index: haml_line_index,
                      skip_line_indexes_in_source_map: source_map_skips,
                      end_marker_indent: following_chunk.end_marker_indent,
                      previous_chunk: previous_chunk)
    end

    def start_marker_indent
      default_indent = super
      default_indent += 2 if MID_BLOCK_KEYWORDS.include?(ChunkExtractor.block_keyword(ruby_lines.first))
      [default_indent, previous_chunk&.end_marker_indent || previous_chunk&.start_marker_indent].compact.max
    end

    def transfer_correction_logic(coordinator, to_ruby_lines, haml_lines) # rubocop:disable Metrics
      to_ruby_lines.reject! { |l| l.strip == 'end' }

      output_comment_prefix = ' ' + coordinator.script_output_prefix.rstrip
      to_ruby_lines.map! do |line|
        if line.lstrip.start_with?('#' + output_comment_prefix)
          line = line.dup
          comment_index = line.index('#')
          removal_start_index = comment_index + 1
          removal_end_index = removal_start_index + output_comment_prefix.size
          line[removal_start_index...removal_end_index] = ''
          # It will be removed again below, but will know its suposed to be a =
          line.insert(comment_index, coordinator.script_output_prefix)
        end
        line
      end

      continued_line_indent_delta = 2

      to_haml_lines = to_ruby_lines.map.with_index do |line, i|
        if line !~ /\S/
          # whitespace or empty lines, we don't want any indentation
          ''
        elsif line_starts_script?(to_ruby_lines, i)
          code_start = line.index(/\S/)
          if line[code_start..].start_with?(coordinator.script_output_prefix)
            line = line.sub(coordinator.script_output_prefix, '')
            continued_line_indent_delta = 2 - coordinator.script_output_prefix.size
            "#{line[0...code_start]}= #{line[code_start..]}"
          else
            continued_line_indent_delta = 2
            "#{line[0...code_start]}- #{line[code_start..]}"
          end
        else
          HamlLint::Utils.indent(line, continued_line_indent_delta)
        end
      end

      haml_lines[@haml_line_index..haml_end_line_index] = to_haml_lines
    end

    def unfinished_script_line?(lines, line_index)
      !!lines[line_index][/,[ \t]*\z/]
    end

    def line_starts_script?(lines, line_index)
      return true if line_index == 0
      !unfinished_script_line?(lines, line_index - 1)
    end
  end
end
