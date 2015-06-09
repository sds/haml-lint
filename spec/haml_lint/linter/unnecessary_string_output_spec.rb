require 'spec_helper'

describe HamlLint::Linter::UnnecessaryStringOutput do
  include_context 'linter'

  context 'when tag is empty' do
    let(:haml) { <<-HAML }
      %tag
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

  context 'when tag contains nested text with interpolation' do
    let(:haml) { <<-'HAML' }
      %tag
        Some #{interpolated} text
    HAML

    it { should_not report_lint }
  end

  context 'when script outputs literal string with method called on it' do
    let(:haml) { "= 'user'.pluralize(@users.count)" }

    it { should_not report_lint }
  end

  context 'when script outupts literal string starting with an HTML comment character' do
    let(:haml) { '= "/ Something"' }

    it { should_not report_lint }
  end

  context 'when script outupts literal string starting with a hash sign' do
    let(:haml) { '= "# Something"' }

    it { should_not report_lint }
  end

  context 'when script outupts literal string starting with a dash' do
    let(:haml) { '= "- Something"' }

    it { should_not report_lint }
  end

  context 'when script outupts literal string starting with a equals sign' do
    let(:haml) { '= "= Something"' }

    it { should_not report_lint }
  end

  context 'when script outupts literal string starting with a percent sign' do
    let(:haml) { '= "% Something"' }

    it { should_not report_lint }
  end

  context 'when script outupts literal string starting with a tilde' do
    let(:haml) { '= "~ Something"' }

    it { should_not report_lint }
  end

  context 'when script outupts literal string starting with interpolation' do
    let(:haml) { '= "#{variable}"' }

    it { should report_lint }
  end
end
