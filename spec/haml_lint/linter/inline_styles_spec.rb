require 'spec_helper'

RSpec.describe HamlLint::Linter::InlineStyles do
  include_context 'linter'

  context 'with no inline styles' do
    let(:haml) { '#p' }

    it { should_not report_lint }
  end

  context 'with inline styles' do
    let(:haml) { "#p{style: 'color: red'}" }

    it { should report_lint line: 1 }
  end
end
