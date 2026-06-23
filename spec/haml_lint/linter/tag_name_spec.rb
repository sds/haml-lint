# frozen_string_literal: true

describe HamlLint::Linter::TagName do
  include_context 'linter'

  context 'when a tag is lowercase' do
    let(:haml) { '%article' }
    it { should_not report_lint }
  end

  context 'when a tag is all uppercase' do
    let(:haml) { '%BODY' }
    it { should report_lint line: 1 }
  end

  context 'when a tag has uppercase letters' do
    let(:haml) { '%someTag' }
    it { should report_lint line: 1 }
  end

  context 'when a tag contains underscores' do
    let(:haml) { '%some_tag' }
    it { should_not report_lint }
  end

  context 'with autocorrect' do
    let(:autocorrect) { :safe }

    context 'when a tag is all uppercase' do
      let(:haml) { '%BODY' }

      it 'downcases the tag name' do
        subject
        document.source.should == '%body'
      end

      it 'records the lint as corrected' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == true
      end
    end

    context 'when a mixed-case tag has attributes and content' do
      let(:haml) { '%MyDiv.foo#bar Hello' }

      it 'downcases only the tag name' do
        subject
        document.source.should == '%mydiv.foo#bar Hello'
      end
    end

    context 'when the tag is already lowercase' do
      let(:haml) { '%div' }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled' do
      let(:haml) { "-# haml-lint:disable TagName\n%DIV" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'under :all mode' do
      let(:autocorrect) { :all }
      let(:haml) { '%DIV' }

      it 'also downcases the tag name' do
        subject
        document.source.should == '%div'
      end
    end
  end
end
