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
end
