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
      let(:line) { 6 }
      let(:message) { 'Lint message' }
      let(:cop_name) { 'Lint/SomeCopName' }
      let(:severity) { double('Severity', name: :warning) }

      let(:offence) do
        double('offence', line: line, message: message, cop_name: cop_name, severity: severity)
      end

      it 'uses the source map to transform line numbers' do
        subject.should report_lint line: 3
      end

      context 'and the offence is from an ignored cop' do
        let(:cop_name) { 'Layout/LineLength' }
        it { should_not report_lint }
      end
    end

    context 'when running inspecting a file containing CRLF line endings (#GH-167)' do
      let(:haml) { "- if signed_in?(viewer)\r\n  %span Stuff" }

      it { should_not report_lint }
    end

    context 'when the HAML_LINT_RUBOCOP_CONF environment variable is specified' do
      around do |example|
        HamlLint::Utils.with_environment 'HAML_LINT_RUBOCOP_CONF' => 'some-rubocop.yml' do
          example.run
        end
      end

      it 'specifies the --config flag' do
        expect(rubocop_cli)
          .to have_received(:run).with(array_including('--config', 'some-rubocop.yml'))
      end
    end

    context 'with config_file config' do
      let(:config) { { 'config_file' => '.haml-cop.yml' } }

      it 'specifies the --config flag' do
        expect(rubocop_cli)
          .to have_received(:run).with(array_including('--config', '.haml-cop.yml'))
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
    end
  end

  describe '#lint_file' do
    subject { described_class.new(config).send(:lint_file, rubocop_cli, 'some_file.rb') }

    let(:config) { spy('config') }
    let(:rubocop_cli) { spy('rubocop_cli') }

    before do
      ::RuboCop::CLI.stub(:new).and_return(rubocop_cli)
      rubocop_cli.stub(:run).and_return(rubocop_cli_status)
      HamlLint::OffenseCollector.stub(:offenses).and_return([])
    end

    context 'when RuboCop exits with a success status' do
      let(:rubocop_cli_status) { ::RuboCop::CLI::STATUS_SUCCESS }

      it { should eq [] }
    end

    context 'when RuboCop exits with an offense status' do
      let(:rubocop_cli_status) { ::RuboCop::CLI::STATUS_OFFENSES }

      it { should eq [] }
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
  end
end
