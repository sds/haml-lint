# frozen_string_literal: true

module HamlLint::RubyExtraction
  class UnableToTransferCorrections < StandardError; end

  # Coordinates the entire RubyExtraction system.
  #
  # * Uses the extractor to generate chunks.
  # * Preprocess the chunks to cleanup/fuse some of them.
  # * Generates the extracted ruby code from the Chunks.
  # * Handles the markers (see below)
  # * Use the chunks to transfer corrections from corrected Ruby code back to HAML
  #
  # The generated Ruby code uses markers to wrap around the Ruby code from the chunks.
  # Those markers look like function calls, like: `haml_lint_marker_1`, so are valid ruby.
  # After RuboCop does it's auto-correction, the markers are used to find the pieces of the
  # corrected Ruby code that correspond to each Chunk.
  class Coordinator
    # @return [String] The prefix used for to handle `= foo` script's in the extracted Ruby code.
    attr_reader :script_output_prefix

    # @return [String] The prefix used for markers in the Ruby code
    attr_reader :marker_prefix

    # @return [Array<String>] The ruby lines after extraction from HAML (before RuboCop)
    attr_reader :assembled_ruby_lines

    # @return [Array<String>] The ruby lines after correction by RuboCop
    attr_reader :corrected_ruby_lines

    def initialize(document)
      @document = document
      @ruby_chunks = nil
      @assembled_ruby_lines = nil
      @corrected_ruby_lines = nil
      @source_map = {}
      @script_output_prefix = nil

      @haml_lines = nil
    end

    def extract_ruby_source
      return @ruby_source if @ruby_source

      pick_a_marker_prefix
      pick_a_script_output_prefix

      @ruby_chunks = HamlLint::RubyExtraction::ChunkExtractor.new(@document,
                                                                  script_output_prefix: @script_output_prefix).extract
      preprocess_chunks

      @assembled_ruby_lines = []
      @ruby_chunks.each do |ruby_chunk|
        ruby_chunk.full_assemble(self)
      end

      # Making sure the generated source has a final newline
      @assembled_ruby_lines << '' if @assembled_ruby_lines.last && !@assembled_ruby_lines.last.empty?

      @ruby_source = RubySource.new(@assembled_ruby_lines.join("\n"), @source_map, @ruby_chunks)
    end

    def preprocess_chunks
      return if @ruby_chunks.size < 2

      new_chunks = [@ruby_chunks.first]
      @ruby_chunks[1..].each do |ruby_chunk|
        fused_chunk = new_chunks.last.fuse(ruby_chunk)
        if fused_chunk
          new_chunks[-1] = fused_chunk
        else
          new_chunks << ruby_chunk
        end
      end
      @ruby_chunks = new_chunks
    end

    def haml_lines_with_corrections_applied(corrected_ruby_source)
      @corrected_ruby_lines = corrected_ruby_source.split("\n")

      @haml_lines = @document.source_lines.dup

      if markers_conflict?(@assembled_ruby_lines, @corrected_ruby_lines)
        raise UnableToTransferCorrections, 'The changes in the corrected ruby are not supported'
      end

      finished_with_empty_line = @haml_lines.last.empty?

      # Going in reverse order, so that if we change the number of lines then the
      # rest of the file will not be offset, which would make things harder
      @ruby_chunks.reverse_each do |ruby_chunk|
        ruby_chunk.transfer_correction(self, @corrected_ruby_lines, @haml_lines)
      end

      if finished_with_empty_line && !@haml_lines.last.empty?
        @haml_lines << ''
      end
      @haml_lines
    end

    def add_lines(lines, haml_line_index:, skip_indexes_in_source_map: [])
      nb_skipped_source_map_lines = 0
      lines.size.times do |i|
        if skip_indexes_in_source_map.include?(i)
          nb_skipped_source_map_lines += 1
        end

        line_number = haml_line_index + 1
        # If we skip the first line, we want to them to have the number of the following line
        line_number = [line_number, line_number + i - nb_skipped_source_map_lines].max
        @source_map[@assembled_ruby_lines.size + i + 1] = line_number
      end
      @assembled_ruby_lines.concat(lines)
    end

    def line_count
      @assembled_ruby_lines.size
    end

    def add_marker(indent, haml_line_index:, name: 'marker')
      add_lines(["#{' ' * indent}#{marker_prefix}_#{name}_#{@assembled_ruby_lines.size + 1}"],
                haml_line_index: haml_line_index)
      line_count
    end

    # If the ruby_lines have different markers in them, or are in a different order,
    # then RuboCop did not alter them in a way that is compatible with this system.
    def markers_conflict?(from_ruby_lines, to_ruby_lines)
      from_markers = from_ruby_lines.grep(/#{marker_prefix}/, &:strip)
      to_markers = to_ruby_lines.grep(/#{marker_prefix}/, &:strip)
      from_markers != to_markers
    end

    def find_line_index_of_marker_in_corrections(line, name: 'marker')
      marker = "#{marker_prefix}_#{name}_#{line}"

      # In the best cases, the line didn't move
      # Using end_with? because indentation may have been added
      return line - 1 if @corrected_ruby_lines[line - 1]&.end_with?(marker)

      @corrected_ruby_lines.index { |l| l.end_with?(marker) }
    end

    def extract_from_corrected_lines(start_marker_line_number, nb_lines)
      cur_start_marker_index = find_line_index_of_marker_in_corrections(start_marker_line_number)
      return if cur_start_marker_index.nil?

      end_marker_line_number = start_marker_line_number + nb_lines + 1
      cur_end_marker_index = find_line_index_of_marker_in_corrections(end_marker_line_number)
      return if cur_end_marker_index.nil?

      @corrected_ruby_lines[(cur_start_marker_index + 1)..(cur_end_marker_index - 1)]
    end

    def pick_a_marker_prefix
      if @document.source.match?(/\bhaml_lint_/)
        100.times do
          suffix = SecureRandom.hex(10)
          next if @document.source.include?(suffix)
          @marker_prefix = "haml_lint#{suffix}"
          return
        end
      else
        @marker_prefix = 'haml_lint'
      end
    end

    def pick_a_script_output_prefix
      if @document.source.match?(/\bHL\.out\b/)
        100.times do
          suffix = SecureRandom.hex(10)
          next if @document.source.include?(suffix)
          @script_output_prefix = "HL.out#{suffix} = "
          return
        end
      else
        @script_output_prefix = 'HL.out = '
      end
    end
  end
end
