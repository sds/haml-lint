module HamlLint
  # Outputs lints in a simple format with the filename, line number, and lint
  # message.
  class Reporter::DefaultReporter < Reporter
    def report_lints
      sorted_lints = lints.sort_by { |l| [l.filename, l.line] }

      sorted_lints.each do |lint|
        log.info lint.filename, false
        log.log ':', false
        log.bold lint.line, false

        if lint.error?
          log.error ' [E] ', false
        else
          log.warning ' [W] ', false
        end

        if lint.linter
          log.success("#{lint.linter.name}: ", false)
        end

        log.log lint.message
      end
    end
  end
end
