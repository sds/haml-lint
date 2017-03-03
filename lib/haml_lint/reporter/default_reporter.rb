require 'haml_lint/reporter/utils'

module HamlLint
  # Outputs lints in a simple format with the filename, line number, and lint
  # message.
  class Reporter::DefaultReporter < Reporter
    include Reporter::Utils

    def added_lint(lint)
      print_lint(lint)
    end

    def display_report(report)
      print_summary(report)
    end
  end
end
