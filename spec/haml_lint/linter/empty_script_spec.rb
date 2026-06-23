# frozen_string_literal: true

describe HamlLint::Linter::EmptyScript do
  include_context 'linter'

  context 'when silent script contains code' do
    let(:haml) { '- some_expression' }

    it { should_not report_lint }
  end

  context 'when silent script contains no code' do
    let(:haml) { '-' }

    it { should report_lint }
  end

  context 'with autocorrect' do
    context 'under :safe mode (unsafe linter is not applied)' do
      let(:autocorrect) { :safe }
      let(:haml) { "%p One\n-\n%p Two" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end

      it 'records the lint as not corrected' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == false
      end
    end

    context 'under :all mode' do
      let(:autocorrect) { :all }

      context 'when a bare silent script is on its own line' do
        let(:haml) { "%p One\n-\n%p Two" }

        it 'removes the empty script line' do
          subject
          document.source.should == "%p One\n%p Two"
        end

        it 'records the lint as corrected' do
          subject
          subject.lints.first.corrected.should == true
        end
      end

      context 'when the linter is disabled in the file' do
        let(:haml) { "-# haml-lint:disable EmptyScript\n%p One\n-\n%p Two" }

        it 'does not change the source' do
          subject
          document.source_was_changed.should == false
        end
      end
    end
  end
end
