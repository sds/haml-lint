require 'rubocop'
require 'tempfile'

module HamlLint
  class Linter::RubyScript < Linter
    include LinterRegistry

    def initialize
      super
      @rubocop = Rubocop::CLI.new
    end

    def run(parser)
      @parser = parser
      @extractor = ScriptExtractor.new(parser)
      extracted_code = @extractor.extract
      find_lints(extracted_code)
    end

  private

    def find_lints(code)
      original_filename = "#{File.basename(@parser.filename)}_" if @parser.filename
      file = Tempfile.new("haml-lint_#{original_filename}extracted_code")

      begin
        file.write(code)
        file.close

        extract_lints_from_offences(lint_file(file.path))
      ensure
        file.unlink
      end
    end

    # Defined so we can stub the results in tests
    def lint_file(file)
      @rubocop.inspect_file(file)
    end

    # These cops are incredibly noisy with Ruby code extracted from HAML,
    # and are safe to ignore
    IGNORED_COPS = %w[
      BlockNesting
      IfUnlessModifier
      LineLength
      TrailingWhitespace
      WhileUntilModifier
      Void
    ]

    def extract_lints_from_offences(offences)
      offences.each do |offence|
        next if IGNORED_COPS.include?(offence.cop_name)

        @lints << Lint.new(@parser.filename,
                           @extractor.source_map[offence.line],
                           offence.message)
      end
    end
  end
end
