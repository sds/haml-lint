module HamlLint
  # @abstract Abstract lint reporter. Subclass and override {#report_lints} to
  #   implement a custom lint reporter.
  class Reporter
    attr_reader :lints

    # @param logger [HamlLint::Logger]
    # @param lints [Array<HamlLint::Lint>]
    def initialize(logger, report)
      @log = logger
      @lints = report.lints
    end

    def report_lints
      raise NotImplementedError
    end

    private

    attr_reader :log
  end
end
