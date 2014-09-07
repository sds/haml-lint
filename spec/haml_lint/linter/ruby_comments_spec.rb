require 'spec_helper'

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
end
