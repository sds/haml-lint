# frozen_string_literal: true

describe HamlLint::Linter::ClassesBeforeIds do
  include_context 'linter'

  context 'when tag has no classes or IDs' do
    let(:haml) { '%tag' }

    it { should_not report_lint }
  end

  context 'when tag has only a class' do
    let(:haml) { '.class' }

    it { should_not report_lint }
  end

  context 'when tag has only classes' do
    let(:haml) { '.class1.class2.class3' }

    it { should_not report_lint }
  end

  context 'when tag has only an ID' do
    let(:haml) { '#id' }

    it { should_not report_lint }
  end

  context 'when tag has only IDs' do
    let(:haml) { '#id1#id2#id3' }

    it { should_not report_lint }
  end

  context 'when configured with classes first (by default)' do
    context 'when tag has classes before IDs' do
      let(:haml) { '.class1.class2.class3#id1#id2#id3' }

      it { should_not report_lint }
    end

    context 'when tag has IDs before classes' do
      let(:haml) { '#id1#id2#id3.class1.class2.class3' }

      it do
        should report_lint(
          message: 'Classes should be listed before IDs (.class1 should precede #id3)'
        )
      end
    end
  end

  context 'when configured with ids first' do
    let(:config) { super().merge('EnforcedStyle' => 'id') }

    context 'when tag has IDs before classes' do
      let(:haml) { '#id1#id2#id3.class1.class2.class3' }

      it { should_not report_lint }
    end

    context 'when tag has classes before IDs' do
      let(:haml) { '.class1.class2.class3#id1#id2#id3' }

      it do
        should report_lint(
          message: 'IDs should be listed before Classes (#id1 should precede .class3)'
        )
      end
    end
  end

  context 'when tag has a class then ID then class' do
    let(:haml) { '.class1#id.class2' }

    it do
      should report_lint(
        message: 'Classes should be listed before IDs (.class2 should precede #id)'
      )
    end
  end

  context 'when tag has an ID then class then ID' do
    let(:haml) { '#id1.class#id2' }

    it do
      should report_lint(
        message: 'Classes should be listed before IDs (.class should precede #id1)'
      )
    end
  end

  context 'with autocorrect' do
    let(:autocorrect) { :safe }

    context 'when configured with classes first (by default)' do
      context 'when tag has IDs before classes' do
        let(:haml) { '#id1#id2#id3.class1.class2.class3' }

        it 'reorders the classes before the IDs' do
          subject
          document.source.should == '.class1.class2.class3#id1#id2#id3'
        end

        it 'records the lint as corrected' do
          subject
          subject.lints.size.should == 1
          subject.lints.first.corrected.should == true
        end
      end

      context 'when tag has a class then ID then class' do
        let(:haml) { '.class1#id.class2' }

        it 'groups all classes before the ID' do
          subject
          document.source.should == '.class1.class2#id'
        end
      end

      context 'when tag has an ID then class then ID' do
        let(:haml) { '#id1.class#id2' }

        it 'groups the class before all IDs' do
          subject
          document.source.should == '.class#id1#id2'
        end
      end

      context 'when tag is already ordered' do
        let(:haml) { '.class1.class2#id1#id2' }

        it 'does not change the source' do
          subject
          document.source_was_changed.should == false
        end
      end
    end

    context 'when configured with ids first' do
      let(:config) { super().merge('EnforcedStyle' => 'id') }
      let(:haml) { '.class1.class2.class3#id1#id2#id3' }

      it 'reorders the IDs before the classes' do
        subject
        document.source.should == '#id1#id2#id3.class1.class2.class3'
      end
    end

    context 'when the linter is disabled inline' do
      let(:haml) { "-# haml-lint:disable ClassesBeforeIds\n#id.class" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'under :all mode' do
      let(:autocorrect) { :all }
      let(:haml) { '#id1#id2#id3.class1.class2.class3' }

      it 'also reorders the classes before the IDs' do
        subject
        document.source.should == '.class1.class2.class3#id1#id2#id3'
      end
    end
  end
end
