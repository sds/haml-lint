# frozen_string_literal: true

module HamlLint::RubyExtraction
  # This chunk just adds its code to the ruby, but does not attempt to transfer their correction
  # in any way.
  #
  # Used for piece of code that just need to be in the generated ruby for reasons specific to
  # the use cases, such as needing a `begin` to do add indentation.
  class AdHocChunk < BaseChunk
    def initialize(*args, **kwargs)
      super(*args, **kwargs.merge(end_marker_indent: nil))
    end

    def wrap_in_markers
      false
    end

    def transfer_correction(coordinator, all_corrected_ruby_lines, haml_lines); end

    def skip_line_indexes_in_source_map
      (0...@ruby_lines.size).to_a
    end
  end
end
