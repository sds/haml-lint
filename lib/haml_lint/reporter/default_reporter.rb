# frozen_string_literal: true

require_relative 'utils'

module HamlLint
  # Outputs lints in a simple format with the filename, line number, and lint
  # message.
  class Reporter::DefaultReporter < Reporter
    include Reporter::Utils

    def added_lint(lint, report)
      print_lint(lint) if lint.severity >= report.fail_level
    end

    def display_report(report)
      print_summary(report)
    end
  end
end
