module HamlLint
  # Contains information about all lints detected during a scan.
  class Report
    attr_accessor :lints
    attr_reader :files

    def initialize(lints, files)
      @lints = lints.sort_by { |l| [l.filename, l.line] }
      @files = files
    end

    def failed?
      @lints.any?
    end
  end
end
