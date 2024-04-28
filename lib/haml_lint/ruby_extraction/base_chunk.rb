# frozen_string_literal: true

module HamlLint::RubyExtraction
  # This is the base class for all of the Chunks of HamlLint::RubyExtraction.
  # A Chunk represents a part of the HAML file that HamlLint::Linter::RuboCop
  # is processing and will insert some Ruby code in a file passed to RuboCop.
  #
  # There are chunks for most HAML concepts, even if they don't represent Ruby
  # code. For example, there is a chunk that represents a `%div` tag, which
  # uses a `begin` in the generated Ruby to add indentation for the children
  # of the %div in the Ruby file just like there is in the HAML file.
  class BaseChunk
    COMMA_CHANGES_LINES = true

    # @return [HamlLint::Tree::Node] Haml node that this comes from
    attr_reader :node

    # @return [Integer] First line index of the auto-correctable code in the Haml source
    #   Usually same as node.line - 1, but some cases, such as interpolation in a filter will
    #   will be different.
    attr_reader :haml_line_index

    # @return [Integer] Line number of the line marker in the ruby source placed before
    #   this auto-correctable code
    attr_reader :start_marker_line_number

    # @return [Integer] The indentation (number of spaces) to use to index the marker
    #   that follows this chunk. Unlike the marker before, this one can vary.
    attr_reader :end_marker_indent

    # @return [Array<String>] The ruby lines that this chunk will insert
    attr_reader :ruby_lines

    def initialize(node,
                   ruby_lines,
                   end_marker_indent:, haml_line_index: node.line - 1)
      ruby_lines = [ruby_lines] if ruby_lines.is_a?(String)
      @node = node
      @ruby_lines = ruby_lines
      @haml_line_index = haml_line_index
      @end_marker_indent = end_marker_indent
    end

    # To be overridden in subclasses.
    # Return a new chunk which is the result of fusing self with the given following chunk.
    # If no fusion is possible, returns nil
    def fuse(_following_chunk)
      nil
    end

    # Overwrites haml_lines to match the Ruby code that was corrected by RuboCop which is in
    # all_corrected_ruby_lines. This can change non-ruby parts to, especially for
    # indentation.
    #
    # This will be called on ruby chunks in the reverse order they were created. Two benefits
    # of this approach:
    # * No need to track when lines in haml_lines are moved to apply changes later in the file
    # * When fixing indentation of lines that follow a corrected line, those following lines will
    #   already have been corrected and so require nothing.
    # Can be overridden by subclasses to make it do nothing
    def transfer_correction(coordinator, _all_corrected_ruby_lines, haml_lines)
      to_ruby_lines = coordinator.extract_from_corrected_lines(@start_marker_line_number, @ruby_lines.size)
      transfer_correction_logic(coordinator, to_ruby_lines, haml_lines)
    end

    # To be overridden by subclasses.
    #
    # Logic to transfer the corrections that turned from_ruby_lines into to_ruby_lines.
    #
    # This method only received the ruby code that belongs to this chunk. (It was
    # extracted using #extract_from by #transfer_correction)
    def transfer_correction_logic(_coordinator, _to_ruby_lines, _haml_lines)
      raise "Implement #transfer_correction_logic in #{self.class.name}"
    end

    def start_marker_indent
      ruby_lines.first[/ */].size
    end

    def haml_end_line_index
      # the .max is needed to handle cases with 0 nb_haml_lines
      [@haml_line_index + nb_haml_lines - 1, @haml_line_index].max
    end

    def nb_haml_lines
      @ruby_lines.size - skip_line_indexes_in_source_map.size
    end

    def full_assemble(coordinator)
      if wrap_in_markers
        @start_marker_line_number = coordinator.add_marker(start_marker_indent,
                                                           haml_line_index: haml_line_index)
        assemble_in(coordinator)
        coordinator.add_marker(@end_marker_indent, haml_line_index: haml_end_line_index)
      else
        assemble_in(coordinator)
      end
    end

    def assemble_in(coordinator)
      coordinator.add_lines(@ruby_lines,
                            haml_line_index: haml_line_index,
                            skip_indexes_in_source_map: skip_line_indexes_in_source_map)
    end

    def skip_line_indexes_in_source_map
      []
    end

    def wrap_in_markers
      true
    end
  end
end
