# frozen_string_literal: true

require 'rainbow'

require_relative 'utils'

module HamlLint
  # Outputs files as they are output as a simple symbol, then outputs
  # a summary of each lint.
  class Reporter::ProgressReporter < Reporter
    include Reporter::Utils

    DOT = '.'

    def display_report(report)
      lints = report.lints

      log.log("\n\nOffenses:\n", true) if lints.any?
      lints.each { |lint| print_lint(lint) }

      print_summary(report)
    end

    def finished_file(_file, lints)
      report_file_as_mark(lints)
    end

    def start(files)
      log.log("Inspecting #{pluralize('file', count: files.size)}", true)
    end

    private

    def dot
      @dot ||= Rainbow(DOT).green
    end

    def report_file_as_mark(lints)
      mark =
        if lints.empty?
          dot
        else
          worst_lint = lints.max_by(&:severity)
          worst_lint.severity.mark_with_color
        end

      log.log(mark, false)
    end
  end
end
