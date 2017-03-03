require 'spec_helper'

RSpec.describe HamlLint::Linter::RepeatedId do
  include_context 'linter'

  context 'with no repeat ids' do
    let(:haml) { '#don' }

    it { should_not report_lint }
  end

  context 'with repeated ids' do
    let(:haml) { "#don\n.no-id\n#don\n#don" }

    it { should report_lint line: 1, severity: :error }
    it { should report_lint line: 3, severity: :error }
    it { should report_lint line: 4, severity: :error }
  end
end
