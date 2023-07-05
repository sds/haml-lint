# frozen_string_literal: true

module HamlLint::RubyExtraction
  # Chunk for handling the a tag attributes, such as `%div{style: 'yes_please'}`
  class TagAttributesChunk < BaseChunk
    def initialize(*args, indent_to_remove:, **kwargs)
      super(*args, **kwargs)
      @indent_to_remove = indent_to_remove
    end

    def transfer_correction_logic(_coordinator, to_ruby_lines, haml_lines) # rubocop:disable Metrics
      return if @ruby_lines == to_ruby_lines

      affected_haml_lines = haml_lines[@haml_line_index..haml_end_line_index]

      affected_haml = affected_haml_lines.join("\n")

      from_ruby = unwrap(@ruby_lines).join("\n")

      if to_ruby_lines.size > 1
        min_indent = to_ruby_lines.first[/^\s*/]
        to_ruby_lines.each.with_index do |line, i|
          next if i == 0
          next if line.start_with?(min_indent)
          to_ruby_lines[i] = "#{min_indent}#{line.lstrip}"
        end
      end

      to_ruby = unwrap(to_ruby_lines).join("\n")

      affected_start_index = affected_haml.index(from_ruby)
      if affected_start_index
        affected_end_index = affected_start_index + from_ruby.size
      else
        regexp = HamlLint::Utils.regexp_for_parts(from_ruby.split("\n"), "(?:\s*\\|?\n)")
        mo = affected_haml.match(regexp)
        affected_start_index = mo.begin(0)
        affected_end_index = mo.end(0)
      end

      affected_haml[affected_start_index...affected_end_index] = to_ruby

      haml_lines[@haml_line_index..haml_end_line_index] = affected_haml.split("\n")

      if haml_lines[haml_end_line_index].end_with?(' |')
        haml_lines[haml_end_line_index].chop!.rstrip!
      end
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
