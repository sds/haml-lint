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
    def initialize(lints, files, fail_level = :warning)
      @lints = lints.sort_by { |l| [l.filename, l.line] }
      @files = files
      @fail_level = Severity.new(fail_level)
    end

    # Checks whether any lints were over the fail level
    #
    # @return [Boolean]
    def failed?
      @lints.any? { |lint| lint.severity >= fail_level }
    end
  end
end
