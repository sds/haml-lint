# frozen_string_literal: true

describe HamlLint::Linter::EmptyObjectReference do
  include_context 'linter'

  context 'when a tag has no object reference' do
    let(:haml) { '%tag' }

    it { should_not report_lint }
  end

  context 'when a tag contains an object reference' do
    let(:haml) { '%tag[@user]' }

    it { should_not report_lint }
  end

  context 'when a tag contains an object reference and prefix' do
    let(:haml) { '%tag[@user, :greeting]' }

    it { should_not report_lint }
  end

  context 'when a tag has an object reference with nil inside' do
    let(:haml) { '%tag[nil]' }

    it { should_not report_lint }
  end

  context 'when a tag has an empty object reference' do
    let(:haml) { '%tag[]' }

    it { should report_lint }
  end
end
