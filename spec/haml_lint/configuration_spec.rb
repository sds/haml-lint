# frozen_string_literal: true

describe HamlLint::Configuration do
  let(:config) { HamlLint::ConfigurationLoader.default_configuration }

  describe '#initialize' do
    let(:config) { described_class.new(hash) }
    subject { config }

    context 'with an empty hash' do
      let(:hash) { {} }

      it 'creates an empty `exclude` section' do
        subject['exclude'].should == []
      end

      it 'creates an empty `linters` section' do
        subject['linters'].should == {}
      end
    end

    context 'with a linter with single values in its `include`/`exclude` options' do
      let(:hash) do
        {
          'linters' => {
            'SomeLinter' => {
              'include' => '**/*.haml',
              'exclude' => '**/*.ignore.haml',
            },
          },
        }
      end

      it 'converts the `include` value into an array' do
        subject['linters']['SomeLinter']['include'].should == ['**/*.haml']
      end

      it 'converts the `exclude` value into an array' do
        subject['linters']['SomeLinter']['exclude'].should == ['**/*.ignore.haml']
      end
    end

    context 'with a linter with an invalid severity' do
      let(:hash) do
        {
          'linters' => {
            'SomeLinter' => {
              'severity' => 'invalid',
            },
          },
        }
      end

      it 'raises an exception' do
        expect { subject }.to raise_error HamlLint::Exceptions::ConfigurationError
      end
    end
  end

  describe '#for_linter' do
    subject { config.for_linter(linter) }

    context 'when linter is a Class' do
      let(:linter) { HamlLint::Linter::LineLength }

      it 'returns the configuration for the relevant linter' do
        subject['max'].should == 80
      end
    end

    context 'when linter is a Linter' do
      let(:linter) { HamlLint::Linter::LineLength.new(double) }

      it 'returns the configuration for the relevant linter' do
        subject['max'].should == 80
      end
    end
  end

  describe '#merge' do
    let(:config) { described_class.new(old_hash) }
    subject { config.merge(described_class.new(new_hash)) }

    context 'when exclude is not explicitly declared on child configuration' do
      let(:old_hash) do
        {
          'linters' => {
            'SomeLinter' => {
              'exclude' => ['**/*.ignore.haml'],
            },
          },
        }
      end
      let(:new_hash) do
        {
          'linters' => {
            'SomeLinter' => {
              'enabled' => true,
            },
          },
        }
      end

      it 'uses inherited exclude' do
        subject['linters']['SomeLinter']['exclude'].should == ['**/*.ignore.haml']
      end
    end
  end
end
