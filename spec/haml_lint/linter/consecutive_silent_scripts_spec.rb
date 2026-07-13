# frozen_string_literal: true

describe HamlLint::Linter::ConsecutiveSilentScripts do
  include_context 'linter'

  context 'when a script appears on its own' do
    let(:haml) { '- expression' }

    it { should_not report_lint }
  end

  context 'when consecutive scripts appear' do
    context 'and they are under the limit' do
      let(:haml) { "- expression\n" * 2 }

      it { should_not report_lint }
    end

    context 'and they are over the limit' do
      let(:haml) { "- expression\n" * 3 }

      it { should report_lint line: 1 }
      it { should_not report_lint line: 2 }
      it { should_not report_lint line: 3 }

      context 'but the linter is disabled in the file' do
        let(:haml) { "-# haml-lint:disable ConsecutiveSilentScripts\n" + super() }

        it { should_not report_lint }
      end

      context 'and they contain nested content that results in output' do
        let(:haml) { <<-HAML }
          - if expression
            = some_output
            %br
          - if expression2
            = some_output2
            %br
          - if expression3
            = some_output3
            %br
        HAML

        it { should_not report_lint }
      end
    end
  end

  context 'when the max_consecutive option is set' do
    let(:config) { super().merge('max_consecutive' => 3) }
    let(:haml) { ("- expression\n" * 3) + "%tag\n" + ("- expression\n" * 4) }

    it { should_not report_lint line: 1 }
    it { should report_lint line: 5 }

    context 'but the linter is disabled in the file' do
      let(:haml) { "-# haml-lint:disable ConsecutiveSilentScripts\n" + super() }

      it { should_not report_lint }
    end
  end

  context 'with autocorrect' do
    let(:autocorrect) { :all }

    context 'when consecutive scripts are over the limit' do
      let(:haml) { "- a = 1\n- b = 2\n- c = 3" }

      it 'merges them into a `:ruby` filter block' do
        subject
        document.source.should == ":ruby\n  a = 1\n  b = 2\n  c = 3"
      end

      it 'records a single corrected lint' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == true
      end
    end

    context 'when the scripts are nested under a tag' do
      let(:haml) { "%div\n  - a = 1\n  - b = 2\n  - c = 3" }

      it 'preserves the indentation of the block' do
        subject
        document.source.should == "%div\n  :ruby\n    a = 1\n    b = 2\n    c = 3"
      end
    end

    context 'when the run is longer than the minimum' do
      let(:haml) { "- a = 1\n- b = 2\n- c = 3\n- d = 4\n- e = 5" }

      it 'merges the whole run into one block and reports it once' do
        subject
        subject.lints.size.should == 1
        document.source.should == ":ruby\n  a = 1\n  b = 2\n  c = 3\n  d = 4\n  e = 5"
      end
    end

    context 'under :safe mode' do
      let(:autocorrect) { :safe }
      let(:haml) { "- a = 1\n- b = 2\n- c = 3" }

      it 'reports the lint but does not correct it' do
        subject
        subject.lints.first.corrected.should == false
        document.source_was_changed.should == false
      end
    end

    context 'when the scripts are under the limit' do
      let(:haml) { "- a = 1\n- b = 2" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled inline' do
      let(:haml) { "-# haml-lint:disable ConsecutiveSilentScripts\n- a = 1\n- b = 2\n- c = 3" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end
  end
end
