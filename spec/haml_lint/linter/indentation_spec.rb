# frozen_string_literal: true

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

    context 'when preferred width is 2 spaces' do
      it { should_not report_lint }
    end

    context 'when preferred width is 1 space' do
      let(:config) { super().merge('width' => 1) }

      it { should report_lint line: 2 }
    end

    context 'when preferred width is 4 spaces' do
      let(:config) { super().merge('width' => 4) }

      it { should report_lint line: 2 }
    end

    context 'when preferred width is unset' do
      let(:config) { super().merge('width' => nil) }

      it { should_not report_lint }
    end
  end

  context 'when haml element spans multiple lines' do
    let(:haml) { <<-HAML }
      %span{ alpha: :bravo,
             charlie: :delta }
    HAML

    it { should_not report_lint }

    context 'and a child element is properly indented' do
      let(:haml) { <<-HAML }
        %span{ alpha: :bravo,
               charlie: :delta }
          Hello
      HAML

      it { should_not report_lint }
    end

    context 'but a child element is improperly indented' do
      let(:haml) { <<-HAML }
        %span{ alpha: :bravo,
               charlie: :delta }
            Hello
      HAML

      it { should report_lint line: 3 }
    end
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

      context 'and should ignore the preferred width' do
        let(:config) { super().merge('width' => 42) }

        it { should_not report_lint }
      end
    end
  end
end
