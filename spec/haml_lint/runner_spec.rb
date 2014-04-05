require 'spec_helper'

describe HamlLint::Runner do
  let(:options) { {} }
  let(:runner)  { HamlLint::Runner.new }

  class FakeLinter1 < HamlLint::Linter; include HamlLint::LinterRegistry; end
  class FakeLinter2 < HamlLint::Linter; include HamlLint::LinterRegistry; end

  before do
    HamlLint::LinterRegistry.stub(:linters).and_return([FakeLinter1, FakeLinter2])
    runner.stub(:extract_applicable_files).and_return(files)
  end

  describe '#run' do
    let(:files) { %w[file1.haml file2.haml] }
    let(:mock_linter) { double('linter', lints: []) }

    let(:options) do
      {
        files: files,
      }
    end

    subject { runner.run(options) }

    before do
      runner.stub(:find_lints).and_return([])
    end

    it 'searches for lints in each file' do
      runner.should_receive(:find_lints).exactly(files.size).times
      subject
    end

    context 'when the :excluded_linters option is specified' do
      let(:options) { super().merge(excluded_linters: ['FakeLinter2']) }

      it 'does not instantiate the excluded linters' do
        FakeLinter2.should_not_receive(:new)
        subject
      end

      it 'instantiates all other linters' do
        FakeLinter1.should_receive(:new).and_return(mock_linter)
        subject
      end
    end

    context 'when the :included_linters option is specified' do
      let(:options) { { included_linters: ['FakeLinter1'] } }

      it 'includes only the specified linter' do
        FakeLinter1.should_receive(:new).and_return(mock_linter)
        FakeLinter2.should_not_receive(:new)
        subject
      end
    end

    context 'when :include_linters and :exclude_linters are specified' do
      let(:options) do
        {
          included_linters: %w[FakeLinter1 FakeLinter2],
          excluded_linters: ['FakeLinter2'],
        }
      end

      it 'does not instantiate the excluded linters' do
        FakeLinter2.should_not_receive(:new)
        subject
      end

      it 'instantiates the included linters' do
        FakeLinter1.should_receive(:new).and_return(mock_linter)
        subject
      end
    end

    context 'when neither included or excluded linters is specified' do
      let(:options) { {} }

      it 'instantiates all registered linters' do
        FakeLinter1.should_receive(:new).and_return(mock_linter)
        FakeLinter2.should_receive(:new).and_return(mock_linter)
        subject
      end
    end

    context 'when all linters are excluded' do
      let(:options) do
        {
          included_linters: %w[FakeLinter1 FakeLinter2],
          excluded_linters: %w[FakeLinter1 FakeLinter2],
        }
      end

      it 'raises an error' do
        expect { subject }.to raise_error HamlLint::Exceptions::NoLintersError
      end
    end
  end
end
