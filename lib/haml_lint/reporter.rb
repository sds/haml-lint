module HamlLint
  # Abstract lint reporter. Subclass and override {#report_lints} to
  # implement a custom lint reporter.
  #
  # @abstract
  class Reporter
    attr_reader :lints
    attr_reader :files

    # @param logger [HamlLint::Logger]
    # @param report [HamlLint::Report]
    def initialize(logger, report)
      @log = logger
      @lints = report.lints
      @files = report.files
    end

    # Implemented by subclasses to display lints from a {HamlLint::Report}.
    def report_lints
      raise NotImplementedError
    end

    # Keep tracking all the descendants of this class for the list of available reporters
    def self.descendants
      @descendants ||= []
    end

    def self.inherited(descendant)
      descendants << descendant
    end

    private

    attr_reader :log
  end
end
