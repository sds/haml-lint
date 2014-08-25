require 'spec_helper'

describe HamlLint::Linter::RuboCop do

  # Need this block before including linter context so that stubbing occurs
  # before linter is run
  before { subject.stub(:lint_file).and_return([offence].compact) }

  include_context 'linter'

  let(:haml) { <<-HAML }
    %span To be
    %span= "or not"
    %span to be
  HAML

  context 'when RuboCop does not report offences' do
    let(:offence) { nil }
    it { should_not report_lint }
  end

  context 'when RuboCop reports offences' do
    let(:line) { 1 }
    let(:message) { 'Lint message' }
    let(:cop_name) { 'Lint/SomeCopName' }

    let(:offence) do
      double('offence', line: line, message: message, cop_name: cop_name)
    end

    it 'uses the source map to transform line numbers' do
      subject.should report_lint line: 2
    end

    context 'and the offence is from an ignored cop' do
      let(:cop_name) { 'Metrics/LineLength' }
      it { should_not report_lint }
    end
  end
end
