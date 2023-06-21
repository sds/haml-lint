# frozen_string_literal: true

module HamlLint::RubyExtraction
  # Chunk for handling the a tag attributes, such as `%div{style: 'yes_please'}`
  class TagAttributesChunk < BaseChunk
    def initialize(*args, indent_to_remove:, **kwargs)
      super(*args, **kwargs)
      @indent_to_remove = indent_to_remove
    end

    def transfer_correction_logic(_coordinator, to_ruby_lines, haml_lines)
      affected_haml_lines = haml_lines[@haml_line_index..haml_end_line_index]

      affected_haml = affected_haml_lines.join("\n")

      from_ruby = unwrap(@ruby_lines).join("\n")
      to_ruby = unwrap(to_ruby_lines).join("\n")

      affected_start_index = affected_haml.index(from_ruby)
      affected_end_index = affected_start_index + from_ruby.size
      affected_haml[affected_start_index...affected_end_index] = to_ruby

      haml_lines[@haml_line_index..haml_end_line_index] = affected_haml.split("\n")
    end

    def unwrap(lines)
      lines = lines.dup
      lines[0] = lines[0].sub(/^\s*/, '').sub(/W+\(/, '')
      lines[-1] = lines[-1].sub(/\)\s*\Z/, '')

      if @indent_to_remove
        HamlLint::Utils.map_after_first!(lines) do |line|
          line.sub(/^ {1,#{@indent_to_remove}}/, '')
        end
      end
      lines
    end
  end
end
