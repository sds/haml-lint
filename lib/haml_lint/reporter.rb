module HamlLint
  # Abstract lint reporter. Subclass and override {#report_lints} to
  # implement a custom lint reporter.
  #
  # @abstract
  class Reporter
    attr_reader :lints

    # @param logger [HamlLint::Logger]
    # @param report [HamlLint::Report]
    def initialize(logger, report)
      @log = logger
      @lints = report.lints
    end

    # Implemented by subclasses to display lints from a {HamlLint::Report}.
    def report_lints
      raise NotImplementedError
    end

    private

    attr_reader :log
  end
end
