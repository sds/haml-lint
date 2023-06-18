# frozen_string_literal: true

module HamlLint
  # Outputs report as a Ruby Hash for easy use by other tools.
  class Reporter::HashReporter < Reporter
    # Disables this reporter on the CLI since it doesn't output anything.
    #
    # @return [false]
    def self.available?
      false
    end

    def display_report(report)
      lints = report.lints
      grouped = lints.group_by(&:filename)

      {
        metadata: metadata,
        files: grouped.map { |l| map_file(l) },
        summary: {
          offense_count: lints.length,
          target_file_count: grouped.length,
          inspected_file_count: report.files.length,
        },
      }
    end

    private

    def metadata
      {
        haml_lint_version: HamlLint::VERSION,
        ruby_engine:      RUBY_ENGINE,
        ruby_patchlevel:  RUBY_PATCHLEVEL.to_s,
        ruby_platform:    RUBY_PLATFORM,
      }
    end

    def map_file(file)
      {
        path: file.first,
        offenses: file.last.map { |o| map_offense(o) },
      }
    end

    def map_offense(offense)
      {
        severity: offense.severity,
        message: offense.message,
        location: {
          line: offense.line,
        },
      }.tap do |h|
        h[:linter_name] = offense.linter.name if offense.linter
      end
    end
  end
end
