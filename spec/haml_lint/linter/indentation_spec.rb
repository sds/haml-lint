require 'spec_helper'

describe HamlLint::Linter::Indentation do
  include_context 'linter'

  context 'when line contains no indentation' do
    let(:haml) { '%span' }

    it { should_not report_lint }
  end

  context 'when line contains spaces for indentation' do
    let(:haml) { <<-HAML }
      %span
        Hello
    HAML

    it { should_not report_lint }
  end

  context 'when line contains only tabs for indentation' do
    let(:haml) { "%span\n\tHello" }

    it { should report_lint line: 2 }

    context 'but the linter is disabled in the file' do
      let(:haml) { "-# haml-lint:disable Indentation\n" + super() }

      it { should_not report_lint }
    end
  end

  context 'when line contains tabs that are not indentation' do
    let(:haml) { "= '\t'" }

    it { should_not report_lint }
  end

  context 'when tabs are preferred' do
    let(:config) { super().merge('character' => 'tab') }

    context 'when line contains no indentation' do
      let(:haml) { '%span' }

      it { should_not report_lint }
    end

    context 'when line contains spaces for indentation' do
      let(:haml) { "%span\n  Hello" }

      it { should report_lint line: 2 }

      context 'but the linter is disabled in the file' do
        let(:haml) { "-# haml-lint:disable Indentation\n" + super() }

        it { should_not report_lint }
      end
    end

    context 'when line contains only tabs for indentation' do
      let(:haml) { <<-HAML }
        %span
        \tHello
      HAML

      it { should_not report_lint }
    end
  end
end
