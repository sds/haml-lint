# frozen_string_literal: true

# Helpers for parsing examples
module ExamplesParsingHelpers
  module_function

  Example = Struct.new(:name, :string, :path, :first_line_no)

  # Extracts `Example` instances from a text file.
  # The format is described in spec/haml_lint/linter/rubocop_autocorrect_examples/README.md
  def examples_from(path) # rubocop:disable Metrics
    string = File.read(path)
    string = ERB.new(string).result

    examples_lines = string.lines.slice_before(/\A\s*!!!/)
    next_line_number = 1
    examples = examples_lines.flat_map do |example_lines|
      cur_line_number = next_line_number
      next_line_number += example_lines.size

      title_command = example_lines[0].strip
      # Remove the first example when the file starts with comments
      next unless title_command.start_with?('!!!')

      title = title_command.sub('!!!', '').lstrip
      example_string = example_lines[1..].join.rstrip + "\n"

      # Completely remove lines with only a !# comment on them
      example_string = example_string.gsub(/^[ \t]*!#.*\n?/, '')

      # Remove !# comments
      example_string = example_string.gsub(/\s*!#.*/, '')

      if example_string.include?('^')
        silent_example_string = example_string.gsub('^^', '').tr('^', '-').gsub('%%', '')
        out_example_string = example_string.gsub('^^', 'HL.out = ')
                                           .gsub('%%', '         ')
                                           .tr('^', '=')
        [
          Example.new("(^ as -)#{title}", silent_example_string, path, cur_line_number),
          Example.new("(^ as =)#{title}", out_example_string, path, cur_line_number),
        ]
      else
        Example.new(title, example_string, path, cur_line_number)
      end
    end

    examples.compact
  end
end
