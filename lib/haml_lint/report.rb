# frozen_string_literal: true

module HamlLint
  # Contains information about all lints detected during a scan.
  class Report
    # List of lints that were found.
    attr_accessor :lints

    # The level of lint to fail after detecting
    attr_reader :fail_level

    # List of files that were linted.
    attr_reader :files

    # Creates a report.
    #
    # @param lints [Array<HamlLint::Lint>] lints that were found
    # @param files [Array<String>] files that were linted
    # @param fail_level [Symbol] the severity level to fail on
    # @param reporter [HamlLint::Reporter] the reporter for the report
    def initialize(lints: [], files: [], fail_level: :warning, reporter: nil)
      @lints = lints.sort_by { |l| [l.filename, l.line] }
      @files = files
      @fail_level = Severity.new(fail_level)
      @reporter = reporter
    end

    # Adds a lint to the report and notifies the reporter.
    #
    # @param lint [HamlLint::Lint] lint to add
    # @return [void]
    def add_lint(lint)
      lints << lint
      @reporter.added_lint(lint, self)
    end

    # Displays the report via the configured reporter.
    #
    # @return [void]
    def display
      @reporter.display_report(self)
    end

    # Checks whether any lints were at or above the fail level
    #
    # @return [Boolean]
    def failed?
      @lints.any? { |lint| lint.severity >= fail_level }
    end

    # Adds a file to the list of linted files and notifies the reporter.
    #
    # @param file [String] the name of the file that was finished
    # @param lints [Array<HamlLint::Lint>] the lints for the finished file
    # @return [void]
    def finish_file(file, lints)
      files << file
      @reporter.finished_file(file, lints)
    end

    # Notifies the reporter that the report has started.
    #
    # @param files [Array<String>] the files to lint
    # @return [void]
    def start(files)
      @reporter.start(files)
    end
  end
end
