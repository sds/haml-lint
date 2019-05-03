# frozen_string_literal: true

describe HamlLint::Linter::TagName do
  include_context 'linter'

  context 'when a tag is lowercase' do
    let(:haml) { '%article' }
    it { should_not report_lint }
  end

  context 'when a tag is all uppercase' do
    let(:haml) { '%BODY' }
    it { should report_lint line: 1 }
  end

  context 'when a tag has uppercase letters' do
    let(:haml) { '%someTag' }
    it { should report_lint line: 1 }
  end

  context 'when a tag contains underscores' do
    let(:haml) { '%some_tag' }
    it { should_not report_lint }
  end
end
