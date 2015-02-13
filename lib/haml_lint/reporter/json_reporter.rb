module HamlLint
  # Outputs report as a JSON document.
  class Reporter::JsonReporter < Reporter
    def report_lints
      grouped = lints.group_by(&:filename)

      report = {
        metadata: {
          hamllint_version: VERSION,
          ruby_engine:      RUBY_ENGINE,
          ruby_patchlevel:  RUBY_PATCHLEVEL.to_s,
          ruby_platform:    RUBY_PLATFORM,
        },
        files: grouped.map { |l| map_file(l) },
        summary: {
          offense_count: lints.length,
          target_file_count: grouped.length,
          inspected_file_count: files.length,
        },
      }

      log.log report.to_json
    end

    private

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
      }
    end
  end
end
