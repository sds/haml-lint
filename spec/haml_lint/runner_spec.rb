# frozen_string_literal: true

describe HamlLint::Runner do
  let(:base_options) { { reporter: reporter } }
  let(:options) { base_options }
  let(:reporter) { HamlLint::Reporter::HashReporter.new(StringIO.new) }
  let(:runner) { described_class.new }

  describe '#run' do
    subject { runner.run(options) }

    context 'general tests' do
      let(:stubbed_sources) { %w[file1.slim file2.slim].map { |path| HamlLint::Source.new StringIO.new, path } }

      let(:options) do
        base_options.merge(reporter: reporter)
      end

      before do
        runner.stub(:extract_applicable_sources).and_return(stubbed_sources)
        runner.stub(:collect_lints).and_return([])
      end

      it 'searches for lints in each file' do
        runner.should_receive(:collect_lints).exactly(stubbed_sources.size).times
        subject
      end

      context 'when :config_file option is specified' do
        let(:options) { base_options.merge(config_file: 'some-config.yml') }
        let(:config) { double('config') }

        it 'loads that specified configuration file' do
          config.stub(:for_linter).and_return('enabled' => true)

          HamlLint::ConfigurationLoader.should_receive(:load_applicable_config)
                                       .with('some-config.yml')
                                       .and_return(config)
          subject
        end
      end

      context 'when :auto_gen_config option is specified' do
        let(:options) { base_options.merge(auto_gen_config: true) }
        let(:config) { double('config') }

        it 'loads that specified configuration file' do
          config.stub(:for_linter).and_return('enabled' => true)

          HamlLint::ConfigurationLoader.should_receive(:load_applicable_config)
                                       .with(nil, exclude_files: [
                                               HamlLint::ConfigurationLoader::AUTO_GENERATED_FILE
                                             ]).and_return(config)
          subject
        end
      end

      context 'when `exclude` global config option specifies a list of patterns' do
        let(:options) { base_options.merge(config: config, files: files) }
        let(:files) { ['include-this-file.haml'] }
        let(:config) { HamlLint::Configuration.new(config_hash) }
        let(:config_hash) { { 'exclude' => 'exclude-this-file.slim' } }

        before do
          runner.stub(:extract_applicable_sources).and_call_original
        end

        it 'passes the global exclude patterns to the FileFinder' do
          HamlLint::FileFinder.any_instance
                              .should_receive(:find)
                              .with(files, ['exclude-this-file.slim'])
                              .and_return([])
          subject
        end
      end

      context 'when :parallel option is specified' do
        let(:options) { base_options.merge(parallel: true, files: %w[example.haml]) }

        include_context 'isolated environment'

        before do
          runner.unstub(:extract_applicable_sources)
          runner.unstub(:collect_lints)
          `echo "%div{ class:    'foo' } hello" > example.haml`
        end

        it 'warms up the cache in parallel' do
          runner.should_receive(:warm_cache).and_call_original
          subject
        end

        context 'when errors are present' do


          it 'successfully reports those errors' do
            expect(subject.lints.first.message).to match(/Avoid defining `class` in attributes hash/)
          end

          context 'with autocorrect on' do
            let(:options) { super().merge(autocorrect: :all) }

            it 'successfully fixes those errors' do
              expect(subject.lints.detect(&:corrected).message).to match(/Unnecessary spacing detected./)
              expect(File.read('example.haml')).to eq("%div{ class: 'foo' } hello\n")
            end
          end
        end
      end

      context 'when there is a Haml parsing error in a file' do
        let(:options) { base_options.merge(parallel: true, files: %w[inconsistent_indentation.haml]) }

        include_context 'isolated environment'

        before do
          # The runner needs to actually look for files to lint
          runner.unstub(:extract_applicable_sources)
          runner.unstub(:collect_lints)
          haml = "%div\n  %span Hello, world\n\t%span Goodnight, moon"

          `echo "#{haml}" > inconsistent_indentation.haml`
        end

        it 'adds a syntax lint to the output' do
          subject.lints.size.should == 1

          lint = subject.lints.first
          lint.line.should == 2
          lint.filename.should == 'inconsistent_indentation.haml'
          lint.message.should match(/Inconsistent indentation/)
          lint.severity.should == :error

          linter = lint.linter
          linter.name.should == 'Syntax'
        end
      end
    end

    context 'integration tests' do
      context 'when the fail-fast option is specified with fail-level' do
        let(:options) do
          base_options.merge(fail_fast: fail_fast, fail_level: :error, files: %w[example.haml example2.haml])
        end

        include_context 'isolated environment'

        before do
          `echo "#my-id Hello\n#my-id World" > example.haml`
          `echo "-# Hello\n-# World" > example2.haml`
        end

        context 'and it is false' do
          let(:fail_fast) { false }

          it 'reports the warning but does not halt on it' do
            subject.lints.size.should == 3
          end
        end

        context 'and it is true' do
          let(:fail_fast) { true }

          it 'reports the warning and halts on it' do
            subject.lints.size.should == 2
          end
        end
      end
    end

    context 'with the stdin option' do
      let(:options) { base_options.merge(stdin: 'test.html.haml') }
      let(:stdin) { +"= \"Single-quoted strings offense\".capitalize\n" }

      before { $stdin.stub(:read).and_return(stdin) }

      it 'lints input from stdin using the given file name' do
        subject.lints.size.should == 1
        subject.lints.first.filename.should == 'test.html.haml'
        subject.lints.first.message.should match(/Prefer single-quoted strings/)
      end
    end
  end
end
