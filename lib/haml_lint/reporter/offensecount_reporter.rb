# frozen_string_literal: false

module HamlLint
  # Outputs the a list of lints with a count of how many of each were found.
  # Ordered by descending count
  class Reporter::OffensecountReporter < Reporter
    def display_report(report)
      lints = report.lints
      total_count = lints.count
      return if total_count.zero?

      lints.group_by {|l| l.linter.name }
           .map { |linter, lints_for_this_linter| [linter, lints_for_this_linter.size] }.to_h
           .sort_by { |_linter, lint_count| -lint_count }
           .each do |linter, lint_count|
             log.log "#{lint_count.to_s.ljust(total_count.to_s.length + 2)} #{linter}"
      end

      log.log '--'
      log.log "#{total_count}  Total"
    end
  end
end
