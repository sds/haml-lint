module HamlLint
  # Outputs lints in a simple format with the filename, line number, and lint
  # message.
  class Reporter::DefaultReporter < Reporter
    def display_report(report)
      sorted_lints = report.lints.sort_by { |l| [l.filename, l.line] }

      sorted_lints.each do |lint|
        print_location(lint)
        print_type(lint)
        print_message(lint)
      end

      print_summary(report)
    end

    private

    def pluralize(word, count: 1)
      if count.zero? || count > 1
        "#{count} #{word}s"
      else
        "#{count} #{word}"
      end
    end

    def print_location(lint)
      log.info lint.filename, false
      log.log ':', false
      log.bold lint.line, false
    end

    def print_type(lint)
      if lint.error?
        log.error ' [E] ', false
      else
        log.warning ' [W] ', false
      end
    end

    def print_message(lint)
      if lint.linter
        log.success("#{lint.linter.name}: ", false)
      end

      log.log lint.message
    end

    def print_summary(report)
      return unless log.summary_enabled

      print_summary_files(report)
      print_summary_lints(report)

      log.log ' detected'
    end

    def print_summary_files(report)
      log.log "\n#{pluralize('file', count: report.files.count)} inspected, ", false
    end

    def print_summary_lints(report)
      lint_count = report.lints.size
      lint_message = pluralize('lint', count: lint_count)

      if lint_count == 0
        log.log lint_message, false
      else
        log.error lint_message, false
      end
    end
  end
end
