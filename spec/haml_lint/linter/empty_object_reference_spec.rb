# frozen_string_literal: true

describe HamlLint::Linter::EmptyObjectReference do
  include_context 'linter'

  context 'when a tag has no object reference' do
    let(:haml) { '%tag' }

    it { should_not report_lint }
  end

  context 'when a tag contains an object reference' do
    let(:haml) { '%tag[@user]' }

    it { should_not report_lint }
  end

  context 'when a tag contains an object reference and prefix' do
    let(:haml) { '%tag[@user, :greeting]' }

    it { should_not report_lint }
  end

  context 'when a tag has an object reference with nil inside' do
    let(:haml) { '%tag[nil]' }

    it { should_not report_lint }
  end

  context 'when a tag has an empty object reference' do
    let(:haml) { '%tag[]' }

    it { should report_lint }
  end

  context 'with autocorrect' do
    let(:autocorrect) { :safe }

    context 'when a tag has an empty object reference' do
      let(:haml) { '%tag[]' }

      it 'removes the empty object reference' do
        subject
        document.source.should == '%tag'
      end

      it 'records the lint as corrected' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == true
      end
    end

    context 'when the tag has static classes and ids before the object reference' do
      let(:haml) { '%tag.foo#bar[]' }

      it 'removes only the empty object reference' do
        subject
        document.source.should == '%tag.foo#bar'
      end
    end

    context 'when the empty object reference contains whitespace' do
      let(:haml) { '%tag[ ]' }

      it 'removes the empty object reference' do
        subject
        document.source.should == '%tag'
      end
    end

    context 'when the tag content contains brackets' do
      let(:haml) { '%tag[]= foo[]' }

      it 'removes only the object reference, not the content brackets' do
        subject
        document.source.should == '%tag= foo[]'
      end
    end

    context 'when an attribute hash follows the object reference' do
      let(:haml) { '%div[]{a: 1}' }

      it 'removes only the object reference' do
        subject
        document.source.should == '%div{a: 1}'
      end
    end

    context 'when the tag is an implicit div' do
      let(:haml) { '.foo[]' }

      it 'removes the empty object reference' do
        subject
        document.source.should == '.foo'
      end
    end

    context 'when the object reference is not empty' do
      let(:haml) { '%tag[@user]' }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled inline' do
      let(:haml) { "-# haml-lint:disable EmptyObjectReference\n%tag[]" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'under :all mode' do
      let(:autocorrect) { :all }
      let(:haml) { '%tag[]' }

      it 'also removes the empty object reference' do
        subject
        document.source.should == '%tag'
      end
    end
  end
end
