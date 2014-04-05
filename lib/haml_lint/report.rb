module HamlLint
  # Contains information about all lints detected during a scan.
  class Report
    attr_accessor :lints

    def initialize(lints)
      @lints = lints.sort_by { |l| [l.filename, l.line] }
    end

    def failed?
      @lints.any?
    end
  end
end
