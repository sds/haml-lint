# frozen_string_literal: true

describe HamlLint::Linter::FinalNewline do
  include_context 'linter'

  context 'when trailing newline is preferred' do
    let(:config) { super().merge('present' => true) }

    context 'when the file is empty' do
      let(:haml) { '' }

      it { should_not report_lint }
    end

    context 'when the file ends with a newline' do
      let(:haml) { "%span\n" }

      it { should_not report_lint }
    end

    context 'when the file does not end with a newline' do
      let(:haml) { '%span' }

      it { should report_lint line: 1 }

      context 'but the linter is disabled in the file' do
        let(:haml) { "-# haml-lint:disable FinalNewline\n" + super() }

        it { should_not report_lint }
      end
    end

    context 'when the file ends with multiple newlines' do
      let(:haml) { "%span\n\n\n" }

      # The file already ends with a trailing newline,
      # so FinalNewline is satisfied
      it { should_not report_lint }
    end
  end

  context 'when no trailing newline is preferred' do
    let(:config) { super().merge('present' => false) }

    context 'when the file is empty' do
      let(:haml) { '' }

      it { should_not report_lint }
    end

    context 'when the file ends with a newline' do
      let(:haml) { "%span\n" }

      it { should report_lint line: 1 }

      context 'but the linter is disabled in the file' do
        let(:haml) { "-# haml-lint:disable FinalNewline\n" + super() }

        it { should_not report_lint }
      end
    end

    context 'when the file does not end with a newline' do
      let(:haml) { '%span' }

      it { should_not report_lint }
    end
  end

  context 'with autocorrect' do
    let(:autocorrect) { :safe }

    context 'when a trailing newline is preferred' do
      let(:config) { super().merge('present' => true) }

      context 'and the file is missing the final newline' do
        let(:haml) { '%span' }

        it 'appends a single newline' do
          subject
          document.source.should == "%span\n"
        end

        it 'records the lint as corrected' do
          subject
          subject.lints.size.should == 1
          subject.lints.first.corrected.should == true
        end
      end

      context 'and the file already ends with a newline' do
        let(:haml) { "%span\n" }

        it 'does not change the source' do
          subject
          document.source_was_changed.should == false
        end
      end

      context 'and the file ends with multiple newlines' do
        let(:haml) { "%span\n\n\n" }

        it 'leaves the extra newlines for other lint to handle' do
          subject
          document.source_was_changed.should == false
        end
      end

      context 'and the file is empty' do
        let(:haml) { '' }

        it 'does not change the source' do
          subject
          document.source_was_changed.should == false
        end
      end

      context 'and the linter is disabled' do
        let(:haml) { "-# haml-lint:disable FinalNewline\n%span" }

        it 'does not change the source' do
          subject
          document.source_was_changed.should == false
        end
      end
    end

    context 'when no trailing newline is preferred' do
      let(:config) { super().merge('present' => false) }

      context 'and the file ends with a newline' do
        let(:haml) { "%span\n" }

        it 'removes the final newline' do
          subject
          document.source.should == '%span'
        end

        it 'records the lint as corrected' do
          subject
          subject.lints.first.corrected.should == true
        end
      end

      context 'and the file does not end with a newline' do
        let(:haml) { '%span' }

        it 'does not change the source' do
          subject
          document.source_was_changed.should == false
        end
      end

      context 'and the file ends with multiple newlines' do
        let(:haml) { "%span\n\n\n" }

        it 'removes all of the trailing newlines' do
          subject
          document.source.should == '%span'
        end
      end
    end
  end
end
