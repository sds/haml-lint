# Makes writing tests for linters a lot DRYer by taking any currently `haml`
# variable defined via `let` and normalizing it and running the linter against
# it, allowing specs to simply specify whether a lint was reported.
shared_context 'linter' do
  before do
    subject.run(HamlLint::Parser.new(normalize_indent(haml)))
  end
end
