module HamlLint
  # Outputs report as a JSON document.
  class Reporter::JsonReporter < Reporter::HashReporter
    def display_report(report)
      log.log super.to_json
    end
  end
end
