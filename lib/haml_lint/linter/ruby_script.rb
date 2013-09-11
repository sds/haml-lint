require 'tempfile'

module HamlLint
  class Linter::RubyScript < Linter
    include LinterRegistry

    def run(parser)
      @parser = parser
      @extractor = ScriptExtractor.new(parser)
      extracted_code = @extractor.extract
      find_lints(extracted_code)
    end

    # Provides a convenient wrapper that can be stubbed in tests
    def run_ruby_linter(file_path)
      output = `rubocop --format=emacs #{file_path} 2>&1`
      [output, !$?.success?]
    end

  private

    def find_lints(code)
      original_filename = "#{File.basename(@parser.filename)}_" if @parser.filename
      file = Tempfile.new("haml-lint_#{original_filename}extracted_code")

      begin
        file.write(code)
        file.close

        output, has_lints = run_ruby_linter(file.path)
        extract_lints_from_output(output) if has_lints
      ensure
        file.unlink
      end
    end

    def extract_lints_from_output(output)
      output.lines.each do |output_line|
        if match = output_line.match(/^(?:[^:]+):(\d+)(?::\d*:)?(?: .:)? (.*)/)
          line = match[1].to_i
          description = match[2]

          unless ignore_lint?(description)
            @lints << Lint.new(@parser.filename,
                               @extractor.source_map[line],
                               description)
          end
        end
      end
    end

    def ignore_lint?(description)
      [
        /line is too long/i,
        /avoid more than \d+ levels of block nesting/i,
      ].any? { |regex| description.match(regex) }
    end
  end
end
