require 'haml_lint/script_extractor'
require 'rubocop'
require 'tempfile'

module HamlLint
  # Runs Rubocop on Ruby code contained within HAML templates.
  class Linter::RubyScript < Linter
    include LinterRegistry

    def initialize
      super
      @rubocop = Rubocop::CLI.new
    end

    def run(parser)
      @parser = parser
      @extractor = ScriptExtractor.new(parser)
      extracted_code = @extractor.extract.strip

      # Ensure a final newline in the code we feed to Rubocop
      find_lints(extracted_code + "\n") unless extracted_code.empty?
    end

  private

    def find_lints(code)
      original_filename = @parser.filename || 'ruby_script'
      filename = "#{File.basename(original_filename)}.haml_lint.tmp"
      directory = File.dirname(original_filename)

      Tempfile.open(filename, directory) do |f|
        begin
          f.write(code)
          f.close
          extract_lints_from_offences(lint_file(f.path))
        ensure
          f.unlink
        end
      end
    end

    # Defined so we can stub the results in tests
    def lint_file(file)
      @rubocop.run(%w[--format HamlLint::OffenceCollector] << file)
      OffenceCollector.offences
    end

    # These cops are incredibly noisy with Ruby code extracted from HAML,
    # and are safe to ignore
    IGNORED_COPS = %w[
      BlockAlignment
      BlockNesting
      EndAlignment
      FileName
      IfUnlessModifier
      IndentationWidth
      LineLength
      TrailingWhitespace
      Void
      WhileUntilModifier
    ]

    def extract_lints_from_offences(offences)
      offences.select { |offence| !IGNORED_COPS.include?(offence.cop_name) }
              .each do |offence|
        @lints << Lint.new(@parser.filename,
                           @extractor.source_map[offence.line],
                           offence.message)
      end
    end
  end

  # Collects offences detected by Rubocop.
  class OffenceCollector < Rubocop::Formatter::BaseFormatter
    attr_accessor :offences

    class << self
      attr_accessor :offences
    end

    def started(target_files)
      self.class.offences = []
    end

    def file_finished(file, offences)
      self.class.offences += offences
    end
  end
end
