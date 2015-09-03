require 'spec_helper'

describe HamlLint::Linter::RuboCop do
  let!(:rubocop_cli) { spy('rubocop_cli') }

  # Need this block before including linter context so that stubbing occurs
  # before linter is run
  before do
    ::RuboCop::CLI.stub(:new).and_return(rubocop_cli)
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

    let(:offence) do
      double('offence', line: line, message: message, cop_name: cop_name)
    end

    it 'uses the source map to transform line numbers' do
      subject.should report_lint line: 3
    end

    context 'and the offence is from an ignored cop' do
      let(:cop_name) { 'Metrics/LineLength' }
      it { should_not report_lint }
    end
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
end
