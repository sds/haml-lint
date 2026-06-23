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

  context 'with autocorrect' do
    let(:autocorrect) { :safe }

    context 'when lines contain trailing spaces and tabs' do
      let(:haml) { "%p Hello   \n%p\tWorld\t" }

      it 'strips the trailing whitespace' do
        subject
        document.source.should == "%p Hello\n%p\tWorld"
      end

      it 'records the lints as corrected' do
        subject
        subject.lints.size.should == 2
        subject.lints.map(&:corrected).should == [true, true]
      end

      it 'marks the document as changed' do
        subject
        document.source_was_changed.should == true
      end
    end

    context 'when a line is disabled via directive' do
      let(:haml) { "-# haml-lint:disable TrailingWhitespace\n%p keep me   " }

      it 'does not strip the disabled line' do
        subject
        document.source.should == "-# haml-lint:disable TrailingWhitespace\n%p keep me   "
        document.source_was_changed.should == false
      end
    end

    context 'when the file is already clean' do
      let(:haml) { "%p Hello\n%p World\n" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when trailing whitespace is inside a filter block' do
      let(:haml) do
        [
          ':plain',
          '  some text   ',
          '  more text'
        ].join("\n")
      end

      it 'strips the trailing whitespace inside the filter' do
        subject
        document.source.should == ":plain\n  some text\n  more text"
      end
    end

    context 'under :all mode' do
      let(:autocorrect) { :all }
      let(:haml) { '%p Hello   ' }

      it 'also strips the trailing whitespace' do
        subject
        document.source.should == '%p Hello'
      end
    end

    context 'when the document has stripped frontmatter' do
      let(:options) do
        super().merge(config: super()[:config].merge(
          HamlLint::Configuration.new('skip_frontmatter' => true)
        ))
      end
      let(:haml) { "---\ntitle: x\n---\n%p hello   \n" }

      it 'corrects compatibly with the stripped frontmatter' do
        subject
        document.source_was_changed.should == true
        document.source.should == "\n\n\n%p hello\n"
      end
    end
  end
end
