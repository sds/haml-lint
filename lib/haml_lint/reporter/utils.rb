# frozen_string_literal: true

module HamlLint
  class Reporter
    # Formatting helpers for printing the default report format.
    module Utils
      # Pluralizes a word based on a count.
      #
      # @param word [String] the word to pluralize
      # @param count [Integer] the count of items
      # @return [String]
      def pluralize(word, count: 1)
        if count.zero? || count > 1
          "#{count} #{word}s"
        else
          "#{count} #{word}"
        end
      end

      # Prints the lint with its location and severity.
      #
      # @param lint [HamlLint::Lint] the lint to print
      # @return [void]
      def print_lint(lint)
        print_location(lint)
        print_type(lint)
        print_message(lint)
      end

      # Prints the location of a lint.
      #
      # @param lint [HamlLint::Lint] the lint to print
      # @return [void]
      def print_location(lint)
        log.info lint.filename, false
        log.log ':', false
        log.bold lint.line, false
      end

      # Prints the severity of a lint.
      #
      # @param lint [HamlLint::Lint] the lint to print
      # @return [void]
      def print_type(lint)
        message = " [#{lint.severity.mark}] "

        if lint.error?
          log.error message, false
        else
          log.warning message, false
        end
      end

      # Prints the description of a lint.
      #
      # @param lint [HamlLint::Lint] the lint to print
      # @return [void]
      def print_message(lint)
        if lint.corrected
          log.success('[Corrected] ', false)
        end

        if lint.linter
          log.success("#{lint.linter.name}: ", false)
        end

        log.log lint.message
      end

      # Prints a summary of a report when summaries are enabled.
      #
      # @param report [HamlLint::Report] the report to print
      # @return [void]
      def print_summary(report)
        return unless log.summary_enabled

        log.log('')
        print_summary_files(report)

        print_summary_lints(report, is_append: true)

        log.log ' detected', false

        print_summary_corrected_lints(report, is_append: true)
        log.log ''
      end

      # Prints a summary of the number of files linted in a report.
      #
      # @param report [HamlLint::Report] the report to print
      # @return [void]
      def print_summary_files(report)
        log.log "#{pluralize('file', count: report.files.count)} inspected", false
      end

      # Prints a summary of the number of lints found in a report.
      #
      # @param report [HamlLint::Report] the report to print
      # @param is_append [Boolean] if this is appending to a line. Will prefix with ", ".
      # @return [void]
      def print_summary_lints(report, is_append:)
        log.log ', ', false if is_append

        lint_count = report.lints.size
        lint_message = pluralize('lint', count: lint_count)

        if lint_count == 0
          log.log lint_message, false
        else
          log.error lint_message, false
        end
      end

      # Prints a summary of the number of lints corrected in a report.
      #
      # @param report [HamlLint::Report] the report to print
      # @param is_append [Boolean] if this is appending to a line. Will prefix with ", ".
      # @return [void]
      def print_summary_corrected_lints(report, is_append:)
        lint_count = report.lints.count(&:corrected)
        return if lint_count == 0

        log.log ', ', false if is_append

        lint_message = pluralize('lint', count: lint_count)

        log.info lint_message, false
        log.log ' corrected', false
      end
    end
  end
end
