require 'spec_helper'

describe HamlLint::Linter::SpacesForIndentation do
  include_context 'linter'

  # rubocop and overcomit HardTab checks don't like tabs either, but they don't
  # check for hex, so use that to avoid triggering them
  let(:tab) { "\x09" }

  context 'when line contains just a tab in its indentation' do
    let(:haml) { <<-HAML }
      %span
#{tab * 4}- bar
    HAML

    it { should report_lint line: 2 }
  end

  context 'when line contains spaces and a tab in its indentation' do
    let(:haml) { <<-HAML }
      %span
      #{tab}- bar
    HAML

    it { should report_lint line: 2 }
  end

  context 'when line contains no indentation' do
    let(:haml) { '- foo_bar' }

    it { should_not report_lint }
  end

  context 'when line contains a tabs but not in indentation' do
    let(:haml) { '  = "\t"' }

    it { should_not report_lint }
  end

  context 'when line contains no tabs in indentation' do
    let(:haml) { '  - foo_bar' }

    it { should_not report_lint }
  end
end
