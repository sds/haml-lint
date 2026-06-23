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

  context 'with autocorrect' do
    let(:autocorrect) { :safe }

    context 'when the file has one trailing blank line' do
      let(:haml) { "%h1 Hello\n\n" }

      it 'collapses to a single trailing newline' do
        subject
        document.source.should == "%h1 Hello\n"
      end

      it 'records the lint as corrected' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == true
      end
    end

    context 'when the file has several trailing blank lines' do
      let(:haml) { "%h1 Hello\n\n\n\n" }

      it 'collapses to a single trailing newline' do
        subject
        document.source.should == "%h1 Hello\n"
        document.source_was_changed.should == true
      end
    end

    context 'when the file has no trailing blank lines' do
      let(:haml) { "%h1 Hello\n" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the file is empty' do
      let(:haml) { '' }

      it 'does not change the source and does not crash' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled' do
      let(:haml) { "-# haml-lint:disable TrailingEmptyLines\n%h1 Hello\n\n" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end
  end
end
