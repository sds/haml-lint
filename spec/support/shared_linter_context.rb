# Makes writing tests for linters a lot DRYer by taking any currently `haml`
# variable defined via `let` and normalizing it and running the linter against
# it, allowing specs to simply specify whether a lint was reported.
shared_context 'linter' do
  let(:options) do
    {
      config: HamlLint::ConfigurationLoader.default_configuration,
    }
  end

  let(:config) { options[:config].for_linter(described_class) }

  subject { described_class.new(config) }

  before do
    subject.run(HamlLint::Document.new(normalize_indent(haml), options))
  end
end
