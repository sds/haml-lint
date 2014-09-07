require 'spec_helper'

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
    end
  end

  context 'when the max_consecutive option is set' do
    let(:config) { super().merge('max_consecutive' => 3) }
    let(:haml) { ("- expression\n" * 3) + "%tag\n" + ("- expression\n" * 4) }

    it { should_not report_lint line: 1 }
    it { should report_lint line: 5 }
  end
end
