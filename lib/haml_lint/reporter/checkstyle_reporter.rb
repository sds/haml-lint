require 'builder'

module HamlLint
  # Outputs report as an XML checkstyle document.
  class Reporter::CheckstyleReporter < Reporter
    def display_report(report)
      lints = report.lints
      files = lints.group_by(&:filename)

      builder = Builder::XmlMarkup.new(indent: 2)

      builder.instruct!
      xml = builder.checkstyle(version: '5.7') do |b|
        files.each do |filename, offenses|
          b.file(name: filename) do
            render_offenses(b, offenses)
          end
        end
      end

      log.log xml
    end

    private

    def render_offenses(b, offenses)
      offenses.each do |offense|
        b.error(line: offense.line,
                severity: offense.severity,
                message: offense.message,
                source: offense.linter.name)
      end
    end
  end
end
