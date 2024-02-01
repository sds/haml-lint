# frozen_string_literal: true

describe HamlLint::Linter::RuboCop do
  it 'exhaustively maps RuboCop severity levels to HamlLint severity levels' do
    ::RuboCop::Cop::Severity::NAMES.each do |name|
      expect(described_class::SEVERITY_MAP).to have_key(name)
    end
  end

  context 'general testing' do
    let!(:rubocop_cli) { spy('rubocop_cli') }

    # Need this block before including linter context so that stubbing occurs
    # before linter is run
    before do
      rubocop_cli.stub(:run).and_return(::RuboCop::CLI::STATUS_SUCCESS)
      HamlLint::Linter::RuboCop.stub(:rubocop_cli).and_return(rubocop_cli)
      HamlLint::OffenseCollector.stub(:offenses)
                                .and_return([offence].compact)
    end

    include_context 'linter'

    let(:offence) { nil }

    let(:haml) { <<-HAML }
      %span To be
      %span= "or not"
      %span to be
    HAML

    it 'does not specify the --config flag by default' do
      expect(rubocop_cli).to have_received(:run).with(array_excluding('--config'))
    end

    context 'when RuboCop does not report offences' do
      it { should_not report_lint }
    end

    context 'when RuboCop reports offences' do
      let(:line) { 4 }
      let(:message) { 'Lint message' }
      let(:cop_name) { 'Lint/SomeCopName' }
      let(:severity) { double('Severity', name: :warning) }

      let(:offence) do
        double('offence', line: line, message: message, cop_name: cop_name,
               severity: severity, status: :uncorrected)
      end

      it 'uses the source map to transform line numbers' do
        subject.should report_lint line: 2
      end

      context 'and the offence is from an ignored cop' do
        let(:config) { super().merge('ignored_cops' => ['Lint/SomeCopName']) }
        it { should_not report_lint }
      end
    end

    context 'when running inspecting a file containing CRLF line endings (#GH-167)' do
      let(:haml) { "- if signed_in?(viewer)\r\n  %span Stuff" }

      it { should_not report_lint }
    end
  end

  context 'user rubocop config testing' do
    include_context 'linter'

    # The offense is a Lint/UselessAssignment
    let(:haml) { <<~HAML }
      - abc = 123
    HAML

    it 'base case has an offense' do
      should report_lint line: 1, severity: :error, message: /UselessAssignment/
    end

    context 'when the HAML_LINT_RUBOCOP_CONF environment variable specifies an empty config' do
      around do |example|
        config_file = Tempfile.new(%w[my-rubo-cop.yml]).tap do |f|
          f.write('# Nothing special')
          f.close
        end

        HamlLint::Utils.with_environment 'HAML_LINT_RUBOCOP_CONF' => config_file.path do
          example.run
        end
      end

      it 'has still has an offense' do
        should report_lint line: 1, severity: :error, message: /UselessAssignment/
      end
    end

    context 'when the HAML_LINT_RUBOCOP_CONF environment variable specifies a config that disable that cop' do
      around do |example|
        config_file = Tempfile.new(%w[my-rubo-cop.yml]).tap do |f|
          f.write("Lint/UselessAssignment:\n  Enabled: false\n")
          f.close
        end

        HamlLint::Utils.with_environment 'HAML_LINT_RUBOCOP_CONF' => config_file.path do
          example.run
        end
      end

      it "doesn't report the issue" do
        should_not report_lint
      end
    end

    context 'when the HAML_LINT_RUBOCOP_CONF environment variable specifies a relative config that disable that cop' do
      around do |example|
        tmp_dir = File.join(__dir__, '../../tmp')
        FileUtils.mkdir_p(tmp_dir)
        config_file = Tempfile.new(%w[my-rubo-cop.yml], tmp_dir).tap do |f|
          f.write("Lint/UselessAssignment:\n  Enabled: false\n")
          f.close
        end
        rel_config_path = Pathname.new(config_file.path).relative_path_from(File.expand_path('.')).to_s
        HamlLint::Utils.with_environment 'HAML_LINT_RUBOCOP_CONF' => rel_config_path do
          example.run
        end
      end

      it "doesn't report the issue" do
        should_not report_lint
      end
    end

    context 'when the config_file specifies an empty config' do
      let(:config) do
        # need to be an instance variable to avoid the TempFile cleaning up too soon
        @config_file = Tempfile.new(%w[my-rubo-cop.yml]).tap do |f|
          f.write('# Nothing special')
          f.close
        end
        super().merge('config_file' => @config_file.path)
      end

      it 'has still has an offense' do
        should report_lint line: 1, severity: :error, message: /UselessAssignment/
      end
    end

    context 'when the config_file specifies a config that disable that cop' do
      let(:config) do
        # need to be an instance variable to avoid the TempFile cleaning up too soon
        @config_file = Tempfile.new(%w[my-rubo-cop.yml]).tap do |f|
          f.write("Lint/UselessAssignment:\n  Enabled: false\n")
          f.close
        end
        super().merge('config_file' => @config_file.path)
      end

      it "doesn't report the issue" do
        should_not report_lint
      end
    end

    context 'when the config_file specifies a relative config that disable that cop' do
      let(:config) do
        # need to be an instance variable to avoid the TempFile cleaning up too soon
        tmp_dir = File.join(__dir__, '../../tmp')
        FileUtils.mkdir_p(tmp_dir)
        config_file = Tempfile.new(%w[my-rubo-cop.yml], tmp_dir).tap do |f|
          f.write("Lint/UselessAssignment:\n  Enabled: false\n")
          f.close
        end
        rel_config_path = Pathname.new(config_file.path).relative_path_from(File.expand_path('.')).to_s
        super().merge('config_file' => rel_config_path)
      end

      it "doesn't report the issue" do
        should_not report_lint
      end
    end

    context 'respect the .rubocop.yml matching the file location' do
      # Don't auto-run because we need to do some setup first
      let(:run_method_to_use) { nil }
      let(:options) { super().merge(file: "#{@tmpdir}/foo.haml") }

      def run_with_config(config)
        Dir.mktmpdir do |tmpdir|
          @tmpdir = tmpdir
          File.open("#{@tmpdir}/.rubocop.yml", 'w') do |f|
            f.write(config)
            f.close
          end
          subject.run_or_raise(document, autocorrect: autocorrect)
        end
      end

      it 'has a lint on config not affecting that file' do
        run_with_config("Lint/UselessAssignment:\n  Exclude: [foo2.haml]\n")
        should report_lint line: 1, severity: :error, message: /UselessAssignment/
      end

      it 'if the cop is disabled, then no lint expected' do
        run_with_config("Lint/UselessAssignment:\n  Enabled: false\n")
        should_not report_lint
      end

      it 'if the file is excluded from the cop, then no lint expected' do
        run_with_config("Lint/UselessAssignment:\n  Exclude: [foo.haml]\n")
        should_not report_lint
      end
    end
  end

  context 'specific testing' do
    include_context 'linter'

    context 'for a syntax error' do
      let(:haml) do
        [
          ':ruby',
          '  [].each do |f|',
        ].join("\n")
      end

      it { should report_lint line: 2, severity: :error }
    end

    context 'for a simple warning' do
      let(:haml) do
        [
          ':ruby',
          '  a = 1',
        ].join("\n")
      end

      it { should report_lint line: 2, severity: :warning }

      it { should report_lint line: 2, corrected: false }
    end

    context 'indentation detection edge cases' do
      let(:run_method_to_use) { nil }

      context 'A comment ending in `do` must not expect indentation' do
        let(:haml) do
          [
            '- #hello world do',
            'content',
          ].join("\n")
        end

        it do
          expect do
            subject.run_or_raise(document)
          end.not_to raise_error
        end
      end

      context 'Raise if content following a block keyword is not indented' do
        let(:haml) do
          [
            '- if hello',
            'content',
          ].join("\n")
        end

        it do
          expect do
            subject.run_or_raise(document)
          end.to raise_error(/should be followed by indentation/)
        end
      end
    end
  end

  context 'autocorrect testing' do
    context 'autocorrect false' do
      include_context 'linter'
      let(:autocorrect) { false }

      context 'lint says when it was not corrected' do
        let(:haml) { <<~HAML }
          = foo(:bar  =>   42)
        HAML

        it { should report_lint line: 1, corrected: false }

        it { should_not report_lint line: 1, corrected: true }
      end
    end

    context 'autocorrect all' do
      include_context 'linter'
      let(:autocorrect) { :all }

      context 'lint says when it was corrected' do
        let(:haml) { <<~HAML }
          = foo(:bar  =>   42)
        HAML

        it { should report_lint line: 1, corrected: true }

        it { should_not report_lint line: 1, corrected: false }
      end
    end

    context 'autocorrect safe' do
      include_context 'linter'
      let(:autocorrect) { :safe }

      # Need to check for an exception, so must call `run` manually
      let(:run_method_to_use) { nil }

      let(:haml) { <<~HAML }
        = foo(:bar  =>   42)
      HAML

      before do
        subject.run_or_raise(document, autocorrect: autocorrect)
      end

      context 'lint says when it was corrected' do
        let(:haml) { <<~HAML }
          = foo(:bar  =>   42)
        HAML

        it nil do
          should report_lint line: 1, corrected: true
        end

        it nil do
          should_not report_lint line: 1, corrected: false
        end
      end
    end
  end

  describe '#run_rubocop' do
    subject { described_class.new(config).send(:run_rubocop, rubocop_cli, 'foo', 'some_file.rb') }

    let(:config) { {} }
    let(:rubocop_cli) { spy('rubocop_cli') }

    before do
      ::RuboCop::CLI.stub(:new).and_return(rubocop_cli)
      rubocop_cli.stub(:run).and_return(rubocop_cli_status)
      HamlLint::OffenseCollector.stub(:offenses).and_return([])
    end

    context 'when RuboCop exits with a success status' do
      let(:rubocop_cli_status) { ::RuboCop::CLI::STATUS_SUCCESS }

      it { should eq [[], nil] }
    end

    context 'when RuboCop exits with an offense status' do
      let(:rubocop_cli_status) { ::RuboCop::CLI::STATUS_OFFENSES }

      it { should eq [[], nil] }
    end

    context 'when RuboCop exits with an error status' do
      let(:rubocop_cli_status) { ::RuboCop::CLI::STATUS_ERROR }

      it {
        expect { subject }.to raise_error(HamlLint::Exceptions::ConfigurationError,
                                          /RuboCop exited unsuccessfully with status 2/)
      }
    end

    context 'when RuboCop exits with an unexpected status' do
      let(:rubocop_cli_status) { 123 }

      it {
        expect { subject }.to raise_error(HamlLint::Exceptions::ConfigurationError,
                                          /RuboCop exited unsuccessfully with status 123/)
      }
    end

    context 'when RuboCop has an infinite loop' do
      before do
        HamlLint::Utils.stub(:with_captured_streams).and_return(['',
                                                                 'Infinite loop detected in foo.rb and caused by ...'])
      end

      let(:rubocop_cli_status) { ::RuboCop::CLI::STATUS_ERROR }

      it {
        expect { subject }.to raise_error(HamlLint::Exceptions::InfiniteLoopError,
                                          /Infinite loop/)
      }
    end
  end
end
