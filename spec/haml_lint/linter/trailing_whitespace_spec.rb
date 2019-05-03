# frozen_string_literal: true

describe HamlLint::Linter::TrailingWhitespace do
  include_context 'linter'

  context 'when line contains trailing spaces' do
    let(:haml) { '- some_code_with_trailing_whitespace      ' }

    it { should report_lint line: 1 }

    context 'but the linter is disabled in the file' do
      let(:haml) { "-# haml-lint:disable TrailingWhitespace\n" + super() }

      it { should_not report_lint }
    end
  end

  context 'when line contains trailing tabs' do
    let(:haml) { "- some_code_with_trailing_whitespace\t" }

    it { should report_lint line: 1 }

    context 'but the linter is disabled in the file' do
      let(:haml) { "-# haml-lint:disable TrailingWhitespace\n" + super() }

      it { should_not report_lint }
    end
  end

  context 'for a multiline node' do
    let(:haml) do
      [
        '= content_for :head_javascript do',
        '  :plain',
        '    var arch_to_show = "#{@default_architecture}"; ',
        '    var time_to_show = "24";'
      ].join("\n")
    end

    it { should report_lint line: 3 }
  end

  context 'when line contains trailing newline' do
    let(:haml) { "- some_code_with_trailing_whitespace\n" }

    it { should_not report_lint }
  end

  context 'when line contains no trailing whitespace' do
    let(:haml) { '- some_code_without_trailing_whitespace' }

    it { should_not report_lint }
  end
end
