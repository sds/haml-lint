require 'spec_helper'

RSpec.describe HamlLint::Linter::ViewLength do
  include_context 'linter'

  context 'under the line limit' do
    let(:haml) { "a\nb\nc" }

    it { should_not report_lint }
  end

  context 'at the line limit' do
    let(:haml) { "a\n" * 100 }

    it { should_not report_lint }
  end

  context 'over the line limit' do
    let(:haml) { "a\n" * 150 }

    it { should report_lint line: 0 }
  end
end
