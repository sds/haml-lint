# frozen_string_literal: true

RSpec.describe HamlLint::Linter::RepeatedId do
  include_context 'linter'

  context 'with no repeat ids' do
    let(:haml) { '#don' }

    it { should_not report_lint }
  end

  context 'with repeated ids' do
    let(:haml) { "#don\n.no-id\n#don\n#don" }

    it { should report_lint line: 1, severity: :error }
    it { should report_lint line: 3, severity: :error }
    it { should report_lint line: 4, severity: :error }
  end

  context 'with repeated ids across files' do
    let(:haml) { '#don' }

    it 'should not report when run on two separate files' do
      second_document = HamlLint::Document.new(normalize_indent(haml), options)

      subject.run_or_raise(second_document)

      subject.should_not report_lint
    end
  end
end
