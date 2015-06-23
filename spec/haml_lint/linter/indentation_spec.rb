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
    let(:haml) { <<-HAML }
      %span
      \tHello
    HAML

    it { should report_lint line: 2 }
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
      let(:haml) { <<-HAML }
        %span
          Hello
      HAML

      it { should report_lint line: 2 }
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
