# frozen_string_literal: true

describe HamlLint::Linter::AltText do
  include_context 'linter'

  context 'when there is no alt attribute' do
    let(:haml) { '%img' }

    it { should report_lint line: 1 }
  end

  context 'when there is an alt attribute' do
    let(:haml) { '%img{ alt: "A relevant description" }' }

    it { should_not report_lint }
  end
end
