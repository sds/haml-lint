# Makes writing tests for linters a lot DRYer by taking any currently `haml`
# variable defined via `let` and normalizing it and running the linter against
# it, allowing specs to simply specify whether a lint was reported.
shared_context 'linter' do
  before do
    haml_code = haml.to_s

    # We need to strip off the initial indent from each line in so the HAML
    # parser doesn't complain about indentation
    leading_indent = haml_code.match(/^(\s*)/)[1]
    normalized_haml = haml_code.gsub(/\n#{leading_indent}/, "\n").lstrip

    subject.run(HamlLint::Parser.new(normalized_haml))
  end
end
