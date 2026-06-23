# frozen_string_literal: false

module HamlLint
  # Outputs GitHub workflow commands for GitHub check annotations when run within GitHub actions.
  class Reporter::GithubReporter < Reporter
    # Characters to escape within a command message.
    ESCAPE_MAP = { '%' => '%25', "\n" => '%0A', "\r" => '%0D' }.freeze
    # Property values also escape the `:` and `,` that delimit the command.
    PROPERTY_ESCAPE_MAP = ESCAPE_MAP.merge(':' => '%3A', ',' => '%2C').freeze

    include Reporter::Utils

    def added_lint(lint, report)
      severity = lint.severity >= report.fail_level ? 'error' : 'warning'
      print_workflow_command(lint, severity)
    end

    def display_report(report)
      print_summary(report)
    end

    private

    def print_workflow_command(lint, severity)
      log.log "::#{severity} file=#{github_escape_property(lint.filename)}," \
              "line=#{lint.line},title=#{github_escape_property(annotation_title(lint))}" \
              "::#{github_escape(annotation_message(lint))}"
    end

    # Annotation title, naming the linter that produced the lint when known.
    def annotation_title(lint)
      lint.linter ? "haml-lint #{lint.linter.name}" : 'haml-lint'
    end

    # Message body, prefixed with the location and linter so it stays useful in the plain log.
    def annotation_message(lint)
      location = "#{lint.filename}:#{lint.line}"
      location += " #{lint.linter.name}:" if lint.linter
      "#{location} #{lint.message}"
    end

    def github_escape(string)
      string.to_s.gsub(Regexp.union(ESCAPE_MAP.keys), ESCAPE_MAP)
    end

    def github_escape_property(string)
      string.to_s.gsub(Regexp.union(PROPERTY_ESCAPE_MAP.keys), PROPERTY_ESCAPE_MAP)
    end
  end
end
