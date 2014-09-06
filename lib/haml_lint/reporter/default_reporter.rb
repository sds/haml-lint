module HamlLint
  # Outputs lints in a simple format with the filename, line number, and lint
  # message.
  class Reporter::DefaultReporter < Reporter
    def report_lints
      # TODO: Push this hack into the RubyScript linter, as it's the one that
      # returns a nil line number for some Rubocop checks
      sorted_lints = lints.sort_by { |l| [l.filename, l.line || 0] }

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
