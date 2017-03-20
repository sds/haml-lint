require 'spec_helper'

describe HamlLint::Linter::IndentationSpaces do
  include_context 'linter'

  context 'when line contains no indentation' do
    let(:haml) { '%span' }

    it { should_not report_lint }
  end

  context 'when line contains only 1 space for indentation' do
    let(:haml) { "%span\n Hello" }

    it { should report_lint line: 2 }

    context 'but the linter is disabled in the file' do
      let(:haml) { "-# haml-lint:disable IndentationSpaces\n" + super() }

      it { should_not report_lint }
    end
  end

  context 'when line contains 2 spaces for indentation' do
    let(:haml) { "%span\n  Hello" }

    it { should_not report_lint }

    context 'but the linter is configured to use 3 spaces' do
      let(:config) { super().merge('width' => 3) }

      it { should report_lint line: 2 }
    end
  end

  context 'when line contains 3 spaces for indentation' do
    let(:haml) { "%span\n   Hello" }

    it { should report_lint line: 2 }

    context 'but the linter is configured to use 3 spaces' do
      let(:config) { super().merge('width' => 3) }

      it { should_not report_lint }
    end
  end

  context 'when line contains 4 spaces for indentation' do
    let(:haml) { "%span\n  Hello" }

    it { should_not report_lint }
  end

  context 'when line contains tabs for indentation' do
    let(:haml) { "%span\n\tHello" }

    it { should_not report_lint }
  end

  context 'when HAML is split across multiple lines' do
    let(:haml) { "%span{ alpha: 'bravo',\n       charlie: 'delta' }\n  Hello" }

    it { should_not report_lint }

    context 'unless the following line has the wrong number of spaces' do
      let(:config) { super().merge('width' => 3) }

      it { should report_lint }
    end
  end
end
