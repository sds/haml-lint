# frozen_string_literal: true

describe HamlLint::Runner do
  let(:base_options) { { reporter: reporter } }
  let(:options) { base_options }
  let(:reporter) { HamlLint::Reporter::HashReporter.new(StringIO.new) }
  let(:runner) { described_class.new }

  describe '#run' do
    subject { runner.run(options) }

    context 'general tests' do
      let(:stubbed_sources) do
        %w[file1.slim file2.slim].map { |path| HamlLint::Source.new io: StringIO.new, path: path }
      end

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
          `echo "%div{ class:    'foo', id: 'x' } hello" > example.haml`
        end

        it 'warms up the cache in parallel' do
          runner.should_receive(:warm_cache).and_call_original
          subject
        end

        context 'with multiple files' do
          let(:options) { base_options.merge(parallel: true, files: %w[example.haml other.haml]) }

          before do
            File.write('other.haml', "%p hello\n")
            Parallel.stub(:map) do |sources, &block|
              sources.map { |source| block.call(source) }
            end
          end

          it 'builds a fresh linter selector for each parallel job' do
            runner.should_receive(:build_linter_selector).exactly(3).times.and_call_original
            subject
          end
        end

        context 'when errors are present' do
          it 'successfully reports those errors' do
            expect(subject.lints.first.message).to match(/Avoid defining `class` in attributes hash/)
          end

          context 'with autocorrect on' do
            let(:options) { super().merge(autocorrect: :all) }

            it 'successfully fixes those errors' do
              expect(subject.lints.detect(&:corrected).message).to match(/Unnecessary spacing detected./)
              expect(File.read('example.haml')).to eq("%div{ class: 'foo', id: 'x' } hello\n")
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

    context 'with the source-level linters and autocorrect' do
      let(:source_linters) { %w[TrailingWhitespace TrailingEmptyLines FinalNewline] }
      let(:options) do
        base_options.merge(files: %w[example.haml], included_linters: source_linters,
                           autocorrect: autocorrect)
      end
      let(:autocorrect) { :safe }

      include_context 'isolated environment'

      before do
        File.write('example.haml', "%p hello   \n%p world\t\n\n\n")
      end

      it 'fixes trailing whitespace and trailing empty lines in one run' do
        subject
        File.read('example.haml').should == "%p hello\n%p world\n"
      end

      it 'reports the corrected offenses' do
        subject.lints.all?(&:corrected).should == true
        subject.lints.size.should be >= 1
      end

      context 'under :all mode' do
        let(:autocorrect) { :all }

        it 'fixes the file the same way' do
          subject
          File.read('example.haml').should == "%p hello\n%p world\n"
        end
      end

      context 'when a final newline is missing' do
        before { File.write('example.haml', '%p hello   ') }

        it 'strips whitespace and adds the final newline' do
          subject
          File.read('example.haml').should == "%p hello\n"
        end
      end

      context 'with --auto-correct-only' do
        let(:options) { super().merge(autocorrect_only: true) }

        it 'rewrites the file and only reports corrected lints' do
          subject
          File.read('example.haml').should == "%p hello\n%p world\n"
          subject.lints.all?(&:corrected).should == true
        end
      end

      context 'when both FinalNewline and TrailingEmptyLines would act' do
        before { File.write('example.haml', "%p hello\n\n\n") }

        it 'leaves exactly one final newline and no trailing blank lines' do
          subject
          File.read('example.haml').should == "%p hello\n"
        end
      end

      context 'even when FinalNewline is listed before the others' do
        let(:source_linters) { %w[FinalNewline TrailingEmptyLines TrailingWhitespace] }

        it 'applies FinalNewline last, keeping the other linters in order' do
          invoked = []
          source_linters.each do |name|
            klass = HamlLint::Linter.const_get(name)
            klass.any_instance.stub(:run).and_wrap_original do |original, *args, **kwargs|
              invoked << name if kwargs.key?(:autocorrect)
              original.call(*args, **kwargs)
            end
          end

          subject

          invoked.should == %w[TrailingEmptyLines TrailingWhitespace FinalNewline]
        end
      end
    end

    context 'with autocorrect across multiple files' do
      # Linter instances are reused across files, so per-run autocorrect state
      # must be reset between files. Otherwise a corrected file leaks its content
      # into the next file processed by the same linter instance.
      let(:options) do
        base_options.merge(files: %w[a_dirty.haml b_clean.haml],
                           included_linters: %w[TagName], autocorrect: :safe)
      end

      include_context 'isolated environment'

      before do
        File.write('a_dirty.haml', "%DIV foo\n")
        File.write('b_clean.haml', "%span bar\n")
      end

      it 'corrects each file without leaking content between them' do
        subject
        File.read('a_dirty.haml').should == "%div foo\n"
        File.read('b_clean.haml').should == "%span bar\n"
      end
    end

    context 'with MultilineScript autocorrect across multiple files' do
      # MultilineScript accumulates pending merges in instance state; that state
      # must be reset between files, or the merge from a_dirty leaks into b_clean.
      let(:options) do
        base_options.merge(files: %w[a_dirty.haml b_clean.haml],
                           included_linters: %w[MultilineScript], autocorrect: :all)
      end

      include_context 'isolated environment'

      before do
        File.write('a_dirty.haml', "- foo ||\n- bar\n")
        File.write('b_clean.haml', "%p clean\n%p second\n")
      end

      it 'merges only the dirty file and leaves the clean file intact' do
        subject
        File.read('a_dirty.haml').should == "- foo || bar\n"
        File.read('b_clean.haml').should == "%p clean\n%p second\n"
      end
    end

    context 'with EmptyScript autocorrect across multiple files' do
      # EmptyScript accumulates the lines to delete in instance state; that state
      # must be reset between files, or a_dirty's deletion leaks into b_clean.
      let(:options) do
        base_options.merge(files: %w[a_dirty.haml b_clean.haml],
                           included_linters: %w[EmptyScript], autocorrect: :all)
      end

      include_context 'isolated environment'

      before do
        File.write('a_dirty.haml', "- foo\n-\n")
        File.write('b_clean.haml', "%p one\n%p two\n%p three\n")
      end

      it 'deletes only in the dirty file and leaves the clean file intact' do
        subject
        File.read('a_dirty.haml').should == "- foo\n"
        File.read('b_clean.haml').should == "%p one\n%p two\n%p three\n"
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

    context 'with the stdin option, stderr option and autocorrect option' do
      let(:options) { base_options.merge(stdin: 'test.html.haml', stderr: true, autocorrect: :safe) }
      let(:stdin) { +"= \"Single-quoted strings offense\".capitalize\n" }

      before do
        $stdin.stub(:read).and_return(stdin)
        $stdout.stub(:write).and_return(nil)
      end

      it 'lints input from stdin using the given file name and writes autocorrect results to stdout' do
        subject.lints.size.should == 1
        subject.lints.first.filename.should == 'test.html.haml'
        subject.lints.first.message.should match(/Prefer single-quoted strings/)
        $stdout.should have_received(:write).with("= 'Single-quoted strings offense'.capitalize\n")
      end

      context 'for a source-level linter' do
        let(:options) do
          base_options.merge(stdin: 'test.html.haml', stderr: true, autocorrect: :safe,
                             included_linters: %w[TrailingWhitespace])
        end
        let(:stdin) { +"%p hello   \n" }

        it 'writes the corrected source to stdout' do
          subject.lints.first.corrected.should == true
          $stdout.should have_received(:write).with("%p hello\n")
        end
      end
    end
  end
end
