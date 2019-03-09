describe HamlLint::LinterSelector do
  let(:options) { {} }
  let(:config) { HamlLint::ConfigurationLoader.load_hash(config_hash) }

  let(:config_hash) do
    {
      'linters' => {
        'FakeLinter1' => { 'enabled' => true },
        'FakeLinter2' => { 'enabled' => true },
        'FakeLinter3' => { 'enabled' => true },
      },
    }
  end

  let(:linter_selector) { described_class.new(config, options) }

  class FakeLinter1 < HamlLint::Linter; include HamlLint::LinterRegistry; end
  class FakeLinter2 < HamlLint::Linter; include HamlLint::LinterRegistry; end
  class FakeLinter3 < HamlLint::Linter; include HamlLint::LinterRegistry; end

  before do
    HamlLint::LinterRegistry.stub(:linters)
                            .and_return([FakeLinter1, FakeLinter2, FakeLinter3])
  end

  describe '#linters_for_file' do
    let(:file) { 'some-file.haml' }
    subject { linter_selector.linters_for_file(file) }

    context 'with no additional configuration or options' do
      it 'returns all registered linters' do
        subject.map(&:class).should == [FakeLinter1, FakeLinter2, FakeLinter3]
      end
    end

    context 'when a linter is disabled in its configuration' do
      let(:config_hash) do
        {
          'linters' => {
            'FakeLinter1' => { 'enabled' => true },
            'FakeLinter2' => { 'enabled' => false },
            'FakeLinter3' => { 'enabled' => true },
          },
        }
      end

      it 'excludes the disabled linter' do
        subject.map(&:class).should == [FakeLinter1, FakeLinter3]
      end
    end

    context 'when included_linters option was specified' do
      let(:options) { { included_linters: ['FakeLinter1'] } }

      it 'returns only that linter' do
        subject.map(&:class).should == [FakeLinter1]
      end
    end

    context 'when excluded_linters option was specified' do
      let(:options) { { excluded_linters: ['FakeLinter3'] } }

      it 'excludes only that linter' do
        subject.map(&:class).should == [FakeLinter1, FakeLinter2]
      end
    end

    context 'when excluded_linters option specifies an included_linter' do
      let(:options) do
        {
          included_linters: %w[FakeLinter1 FakeLinter3],
          excluded_linters: ['FakeLinter3'],
        }
      end

      it 'returns the difference of the two sets' do
        subject.map(&:class).should == [FakeLinter1]
      end
    end

    context 'when excluded_linters option specifies all included_linters' do
      let(:options) do
        {
          included_linters: %w[FakeLinter1 FakeLinter3],
          excluded_linters: %w[FakeLinter1 FakeLinter3],
        }
      end

      it 'raises an error' do
        expect { subject }.to raise_error HamlLint::Exceptions::NoLintersError
      end
    end

    context 'when all linters are disabled in the configuration' do
      let(:config_hash) do
        {
          'linters' => {
            'FakeLinter1' => { 'enabled' => false },
            'FakeLinter2' => { 'enabled' => false },
            'FakeLinter3' => { 'enabled' => false },
          },
        }
      end

      it 'raises an error' do
        expect { subject }.to raise_error HamlLint::Exceptions::NoLintersError
      end
    end

    context 'when linter specifies `include`/`exclude` in its configuration' do
      let(:include_pattern) { [] }
      let(:exclude_pattern) { [] }

      let(:config_hash) do
        {
          'linters' => {
            'FakeLinter1' => {
              'enabled' => true,
              'include' => include_pattern,
              'exclude' => exclude_pattern,
            },
          },
        }
      end

      context 'and the file matches the include pattern' do
        let(:include_pattern) { '**/some-*.haml' }

        it 'returns the linter' do
          subject.map(&:class).should == [FakeLinter1]
        end
      end

      context 'and the file does not match the include pattern' do
        let(:include_pattern) { '**/nope-*.haml' }

        it 'excludes the linter' do
          subject.map(&:class).should == []
        end
      end

      context 'and the file matches the exclude pattern' do
        let(:exclude_pattern) { '**/some-*.haml' }

        it 'excludes the linter' do
          subject.map(&:class).should == []
        end
      end

      context 'and the file matches both the include and exclude patterns' do
        let(:include_pattern) { '**/*-file.haml' }
        let(:exclude_pattern) { '**/some-*.haml' }

        it 'excludes the linter' do
          subject.map(&:class).should == []
        end
      end
    end
  end
end
