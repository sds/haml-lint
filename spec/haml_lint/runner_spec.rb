require 'spec_helper'

describe HamlLint::Runner do
  let(:base_options) { { reporter: reporter } }
  let(:options) { base_options }
  let(:reporter) { HamlLint::Reporter::HashReporter.new(StringIO.new) }
  let(:runner) { described_class.new }

  before do
    runner.stub(:extract_applicable_files).and_return(files)
  end

  describe '#run' do
    let(:files) { %w[file1.slim file2.slim] }
    let(:mock_linter) { double('linter', lints: [], name: 'Blah') }

    let(:options) do
      base_options.merge(files: files, reporter: reporter)
    end

    subject { runner.run(options) }

    before do
      runner.stub(:collect_lints).and_return([])
    end

    it 'searches for lints in each file' do
      runner.should_receive(:collect_lints).exactly(files.size).times
      subject
    end

    context 'when :config_file option is specified' do
      let(:options) { base_options.merge(config_file: 'some-config.yml') }
      let(:config) { double('config') }

      it 'loads that specified configuration file' do
        config.stub(:for_linter).and_return('enabled' => true)

        HamlLint::ConfigurationLoader.should_receive(:load_file)
                                     .with('some-config.yml')
                                     .and_return(config)
        subject
      end
    end

    context 'when `exclude` global config option specifies a list of patterns' do
      let(:options) { base_options.merge(config: config, files: files) }
      let(:config) { HamlLint::Configuration.new(config_hash) }
      let(:config_hash) { { 'exclude' => 'exclude-this-file.slim' } }

      before do
        runner.stub(:extract_applicable_files).and_call_original
      end

      it 'passes the global exclude patterns to the FileFinder' do
        HamlLint::FileFinder.any_instance
                            .should_receive(:find)
                            .with(files, ['exclude-this-file.slim'])
                            .and_return([])
        subject
      end
    end

    context 'when there is a Haml parsing error in a file' do
      let(:files) { %w[inconsistent_indentation.haml] }

      include_context 'isolated environment'

      before do
        # The runner needs to actually look for files to lint
        runner.should_receive(:collect_lints).and_call_original

        `echo "%div\n  %span Hello, world\n\t%span Goodnight, moon" > inconsistent_indentation.haml`
      end

      it 'adds a syntax lint to the output' do
        subject.lints.size.should == 1

        lint = subject.lints.first
        lint.line.should == 2
        lint.filename.should == 'inconsistent_indentation.haml'
        lint.message.should match(/^Inconsistent indentation/)
        lint.severity.should == :error

        linter = lint.linter
        linter.name.should == 'Syntax'
      end
    end
  end
end
