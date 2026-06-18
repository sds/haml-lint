# frozen_string_literal: true

describe HamlLint::Linter::MultilineScript do
  include_context 'linter'

  context 'when silent script is split with a Boolean operator' do
    let(:haml) { <<-HAML }
      - if condition ||
      - true
        Result
    HAML

    it { should report_lint line: 1 }
  end

  context 'when silent script is split with an equality operator' do
    let(:haml) { <<-HAML }
      - if condition ==
      - something
        Result
    HAML

    it { should report_lint line: 1 }
  end

  context 'when script is split with a binary operator' do
    let(:haml) { <<-HAML }
      = 1 +
      = 2
    HAML

    it { should report_lint line: 1 }
  end

  context 'when begin/rescue are used' do
    let(:haml) { <<-HAML }
      - begin
        = some_helper
      - rescue
        An error occurred
    HAML

    it { should_not report_lint }
  end

  context 'with autocorrect' do
    context 'under :safe mode (unsafe linter is not applied)' do
      let(:autocorrect) { :safe }
      let(:haml) { "= 1 +\n= 2" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end

      it 'records the lint as not corrected' do
        subject
        subject.lints.first.corrected.should == false
      end
    end

    context 'under :all mode' do
      let(:autocorrect) { :all }

      context 'when a binary operator splits a script' do
        let(:haml) { "= 1 +\n= 2" }

        it 'merges the two lines' do
          subject
          document.source.should == '= 1 + 2'
        end

        it 'records the lint as corrected' do
          subject
          subject.lints.first.corrected.should == true
        end
      end

      context 'when a silent script with a child is split' do
        let(:haml) { "- if condition ||\n- true\n  Result" }

        it 'merges the continuation and keeps the child nested' do
          subject
          document.source.should == "- if condition || true\n  Result"
        end
      end

      context 'when a chain of operators spans multiple lines' do
        let(:haml) { "- if a ||\n- b &&\n- c" }

        it 'merges the whole chain onto the root line' do
          subject
          document.source.should == '- if a || b && c'
        end
      end

      context 'when the trailing operator is the last node of a block' do
        let(:haml) { "- if x\n  - foo &&\n- bar" }

        it 'reports the lint but does not merge across the block boundary' do
          subject
          subject.lints.size.should == 1
          document.source_was_changed.should == false
        end
      end

      context 'when the linter is disabled in the file' do
        let(:haml) { "-# haml-lint:disable MultilineScript\n= 1 +\n= 2" }

        it 'does not change the source' do
          subject
          document.source_was_changed.should == false
        end
      end
    end
  end
end
