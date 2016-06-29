module HamlLint
  # Contains information about all lints detected during a scan.
  class Report
    # List of lints that were found.
    attr_accessor :lints
    attr_accessor :fail_level

    # List of files that were linted.
    attr_reader :files

    # Creates a report.
    #
    # @param lints [Array<HamlLint::Lint>] lints that were found
    # @param files [Array<String>] files that were linted
    def initialize(lints, files, fail_level = nil)
      @lints = lints.sort_by { |l| [l.filename, l.line] }
      @files = files
      @fail_level = Severity.new(fail_level) if fail_level
    end

    def failed?
      return @lints.any unless @fail_level

      @lints.find { |lint| lint.severity.level >= @fail_level.level }
    end
  end
end
