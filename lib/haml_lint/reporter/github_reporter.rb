# frozen_string_literal: false

module HamlLint
  # Outputs GitHub workflow commands for GitHub check annotations when run within GitHub actions.
  class Reporter::GithubReporter < Reporter
    ESCAPE_MAP = { '%' => '%25', "\n" => '%0A', "\r" => '%0D' }.freeze

    include Reporter::Utils

    def added_lint(lint, report)
      if lint.severity >= report.fail_level
        print_workflow_command(lint: lint)
      else
        print_workflow_command(severity: 'warning', lint: lint)
      end
    end

    def display_report(report)
      print_summary(report)
    end

    private

    def print_workflow_command(lint:, severity: 'error')
      log.log "::#{severity} file=#{lint.filename},line=#{lint.line}::#{github_escape(lint.message)}"
    end

    def github_escape(string)
      string.gsub(Regexp.union(ESCAPE_MAP.keys), ESCAPE_MAP)
    end
  end
end
