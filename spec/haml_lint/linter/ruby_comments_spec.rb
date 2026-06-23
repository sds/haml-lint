# frozen_string_literal: true

describe HamlLint::Linter::RubyComments do
  include_context 'linter'

  context 'when HAML comment is used' do
    let(:haml) { '-# A HAML comment' }

    it { should_not report_lint }
  end

  context 'when a Ruby comment is used' do
    let(:haml) { '- # A Ruby comment' }

    it { should report_lint }
  end

  context 'with autocorrect' do
    let(:autocorrect) { :safe }

    context 'when a Ruby comment is used' do
      let(:haml) { '- # A Ruby comment' }

      it 'rewrites it as a HAML comment' do
        subject
        document.source.should == '-# A Ruby comment'
      end

      it 'records the lint as corrected' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == true
      end
    end

    context 'when there are several spaces before the `#`' do
      let(:haml) { '-   # A Ruby comment' }

      it 'collapses to the HAML comment marker' do
        subject
        document.source.should == '-# A Ruby comment'
      end
    end

    context 'when a HAML comment is already used' do
      let(:haml) { '-# A HAML comment' }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled' do
      let(:haml) { "-# haml-lint:disable RubyComments\n- # A Ruby comment" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'under :all mode' do
      let(:autocorrect) { :all }
      let(:haml) { '- # A Ruby comment' }

      it 'also rewrites the comment' do
        subject
        document.source.should == '-# A Ruby comment'
      end
    end
  end
end
