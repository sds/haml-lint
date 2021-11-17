# frozen_string_literal: true

module HamlLint::RubyExtraction
  # This chunk just adds a marker (with a custom name) to the generated Ruby and only attempts to
  # transfer the corrections it receives to the indentation of the associated lines.
  #
  # Also used so that Rubocop doesn't think that there is nothing in `if` and other such structures,
  # so that it does corrections that make sense for the HAML.
  class PlaceholderMarkerChunk < BaseChunk
    def initialize(node, marker_name, indent:, nb_lines: 1, **kwargs)
      @marker_name = marker_name
      @indent = indent
      @nb_lines = nb_lines
      super(node, nil, **kwargs.merge(end_marker_indent: @indent))
    end

    def full_assemble(coordinator)
      @start_marker_line_number = coordinator.add_marker(@indent, name: @marker_name,
                                                       haml_line_index: haml_line_index)
    end

    def transfer_correction(coordinator, all_corrected_ruby_lines, haml_lines)
      marker_index = coordinator.find_line_index_of_marker_in_corrections(@start_marker_line_number,
                                                                          name: @marker_name)
      new_indent = all_corrected_ruby_lines[marker_index].index(/\S/)
      return if new_indent == @indent
      (haml_line_index..haml_end_line_index).each do |i|
        haml_lines[i] = HamlLint::Utils.indent(haml_lines[i], new_indent - @indent)
      end
    end

    def haml_end_line_index
      haml_line_index + @nb_lines - 1
    end

    def end_marker_indent
      @indent
    end
  end
end
