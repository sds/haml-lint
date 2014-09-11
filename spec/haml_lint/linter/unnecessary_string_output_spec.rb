require 'spec_helper'

describe HamlLint::Linter::UnnecessaryStringOutput do
  include_context 'linter'

  context 'when tag contains no inline text' do
    let(:haml) { <<-HAML }
      %tag
       Some non-inline text
    HAML
    it { should_not report_lint }
  end

  context 'when tag contains inline text without interpolation' do
    let(:haml) { '%tag Some inline text' }
    it { should_not report_lint }
  end

  context 'when tag outputs string with interpolation' do
    let(:haml) { '%tag= "Some #{interpolation} text"' }
    it { should report_lint }
  end

  context 'when tag contains inline text with interpolation' do
    let(:haml) { '%tag Some #{interpolation} text' }
    it { should_not report_lint }
  end

  context 'when tag contains inline text with double quotes' do
    let(:haml) { '%tag "Some #{interpolation} text"' }
    it { should_not report_lint }
  end

  context 'when tag contains inline text with single quotes' do
    let(:haml) { "%tag 'Some text'" }
    it { should_not report_lint }
  end

  context 'when script outputs literal string in double quotes' do
    let(:haml) { '= "hello #{world}"' }
    it { should report_lint }
  end

  context 'when script outputs literal string in single quotes' do
    let(:haml) { "= 'hello world'" }
    it { should report_lint }
  end
end
