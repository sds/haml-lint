# frozen_string_literal: true

describe HamlLint::Linter::ClassAttributeWithStaticValue do
  include_context 'linter'

  context 'when tag contains no class attribute' do
    let(:haml) { '%tag' }

    it { should_not report_lint }
  end

  context 'when tag contains static class attribute' do
    let(:haml) { '%tag.class' }

    it { should_not report_lint }
  end

  context 'when implicit div contains static class attribute' do
    let(:haml) { '.class' }

    it { should_not report_lint }
  end

  context 'when tag contains dynamic class attribute' do
    let(:haml) { '%tag{ class: status }' }

    it { should_not report_lint }
  end

  context 'when tag contains dynamic class attribute with symbol value' do
    let(:haml) { '%tag{ class: :status }' }

    it { should report_lint }
  end

  context 'when tag contains dynamic class attribute with string value' do
    let(:haml) { "%tag{ class: 'status' }" }

    it { should report_lint }
  end

  context 'when tag contains dynamic class attribute with method call value' do
    let(:haml) { '%th{ class: some_method_call }' }

    it { should_not report_lint }
  end

  context 'when tag contains dynamic class attribute with ivar value' do
    let(:haml) { '%th{ class: @some_ivar }' }

    it { should_not report_lint }
  end

  context 'when tag contains attributes assigned via method call' do
    let(:haml) { '%tag{ some_method_call }' }

    it { should_not report_lint }
  end

  context 'when tag attributes contain syntax errors' do
    let(:haml) { '%th{ :class: value }' }

    it { should_not report_lint }
  end

  context 'when tag attributes contain invalid value' do
    let(:haml) { "%th{ class: '{{value}}' }" }

    it { should_not report_lint }
  end

  context 'when tag attributes are malformed' do
    let(:haml) { %(%input{{type: "radio"}, "a" == "b" ? { checked: "checked" } : {}}) }

    it { should_not report_lint }
  end

  context 'when tag has both HTML-style and hash-style attributes' do
    let(:haml) { <<-HAML }
      - MyStruct = Struct.new(:href)
      - @title = 'Hello'
      - @link = MyStruct.new('blahblah')
      %a(title=@title){:href => @link.href} Stuff
    HAML

    it { should_not report_lint }
  end

  context 'with autocorrect' do
    let(:autocorrect) { :safe }

    context 'when the class is the only attribute' do
      let(:haml) { "%tag{ class: 'status' }" }

      it 'moves the class into the inline syntax' do
        subject
        document.source.should == '%tag.status'
      end

      it 'records the lint as corrected' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == true
      end
    end

    context 'when the class value is a symbol' do
      let(:haml) { '%tag{ class: :status }' }

      it 'moves the class into the inline syntax' do
        subject
        document.source.should == '%tag.status'
      end
    end

    context 'when the tag already has an inline class' do
      let(:haml) { "%tag.existing{ class: 'status' }" }

      it 'appends the class after the existing inline class' do
        subject
        document.source.should == '%tag.existing.status'
      end
    end

    context 'when the tag is an implicit div' do
      let(:haml) { ".foo{ class: 'status' }" }

      it 'appends the class to the implicit div' do
        subject
        document.source.should == '.foo.status'
      end
    end

    context 'when the hash has other attributes' do
      let(:haml) { "%tag{ class: 'status', id: 'x' }" }

      it 'reports the lint without correcting' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == false
        document.source_was_changed.should == false
      end
    end

    context 'when the class value duplicates an existing inline class' do
      let(:haml) { "%tag.status{ class: 'status' }" }

      it 'reports the lint without correcting' do
        subject
        subject.lints.first.corrected.should == false
        document.source_was_changed.should == false
      end
    end

    context 'when the hash spans multiple lines' do
      let(:haml) { "%tag{\n  class: 'status' }" }

      it 'reports the lint without correcting' do
        subject
        subject.lints.first.corrected.should == false
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled' do
      let(:haml) { "-# haml-lint:disable ClassAttributeWithStaticValue\n%tag{ class: 'status' }" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'under :all mode' do
      let(:autocorrect) { :all }
      let(:haml) { "%tag{ class: 'status' }" }

      it 'also moves the class into the inline syntax' do
        subject
        document.source.should == '%tag.status'
      end
    end
  end
end
