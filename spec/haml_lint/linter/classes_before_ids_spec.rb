require 'spec_helper'

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

      it { should report_lint message: 'Classes should be listed before IDs (.class1 should precede #id3)' }
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

      it { should report_lint message: 'IDs should be listed before Classes (#id1 should precede .class3)' }
    end
  end

  context 'when tag has a class then ID then class' do
    let(:haml) { '.class1#id.class2' }

    it { should report_lint message: 'Classes should be listed before IDs (.class2 should precede #id)' }
  end

  context 'when tag has an ID then class then ID' do
    let(:haml) { '#id1.class#id2' }

    it { should report_lint message: 'Classes should be listed before IDs (.class should precede #id1)' }
  end
end
