# frozen_string_literal: true

RSpec.describe HamlLint::Linter::AlignmentTabs do
  include_context 'linter'

  context 'when there are no non-indentation tabs' do
    let(:haml) { '%p Hello' }

    it { should_not report_lint }

    context 'even in a multiline tag that uses tabs for indentation' do
      let(:haml) { "%p\n\t%span Hello\n\t%span world" }

      it { should_not report_lint }
    end
  end

  context 'when there are non-indentation tabs' do
    let(:haml) { "%p\tHello" }

    it { should report_lint }

    context 'in a multiline tag that uses tabs for indentation' do
      let(:haml) { "%p\n\t%span Hello\n\t%span\tworld" }

      it { should report_lint line: 3 }
    end
  end

  context 'with autocorrect' do
    let(:autocorrect) { :all }

    context 'when a tag uses tabs for alignment' do
      let(:haml) { "%p\tHello" }

      it 'collapses the tabs into a single space' do
        subject
        document.source.should == '%p Hello'
      end

      it 'records the lint as corrected' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == true
      end
    end

    context 'when the tag uses tabs for indentation as well' do
      let(:haml) { "%p\n\t%span Hello\n\t%span\tworld" }

      it 'only collapses the alignment tabs, keeping indentation tabs' do
        subject
        document.source.should == "%p\n\t%span Hello\n\t%span world"
      end
    end

    context 'under :safe mode' do
      let(:autocorrect) { :safe }
      let(:haml) { "%p\tHello" }

      it 'reports the lint but does not correct it' do
        subject
        subject.lints.first.corrected.should == false
        document.source_was_changed.should == false
      end
    end

    context 'when there are no alignment tabs' do
      let(:haml) { '%p Hello' }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled inline' do
      let(:haml) { "-# haml-lint:disable AlignmentTabs\n%p\tHello" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end
  end
end
