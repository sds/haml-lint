require 'colorize'

module HamlLint
  class Reporter::DefaultReporter < Reporter
    def report_lints
      if lints.any?
        lints.map do |lint|
          type = lint.error? ? '[E]'.red : '[W]'.yellow
          "#{lint.filename.cyan}:" << "#{lint.line}".magenta <<
                                      " #{type} #{lint.message}"
        end.join("\n") + "\n"
      end
    end
  end
end
