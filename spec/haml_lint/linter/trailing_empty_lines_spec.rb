# frozen_string_literal: true

describe HamlLint::Linter::TrailingEmptyLines do
  include_context 'linter'

  context 'when the file is empty' do
    let(:haml) { '' }

    it { should_not report_lint }
  end

  context 'when file ends with a single newline' do
    let(:haml) { "%h1 Hello\n" }

    it { should_not report_lint }
  end

  context 'when file contains multiple newlines' do
    let(:haml) { "%h1 Hello\n\n" }

    it { should report_lint line: 1 }

    context 'but the linter is disabled in the file' do
      let(:haml) { "-# haml-lint:disable TrailingEmptyLines\n" + super() }

      it { should_not report_lint }
    end
  end
end
