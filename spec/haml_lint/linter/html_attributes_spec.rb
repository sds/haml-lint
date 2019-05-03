# frozen_string_literal: true

describe HamlLint::Linter::HtmlAttributes do
  include_context 'linter'

  context 'when a tag has no attributes' do
    let(:haml) { '%tag' }

    it { should_not report_lint }
  end

  context 'when a tag contains hash attributes' do
    let(:haml) { "%tag{ lang: 'en' }" }

    it { should_not report_lint }
  end

  context 'when a tag contains HTML attributes' do
    let(:haml) { '%tag(lang=en)' }

    it { should report_lint }
  end

  context 'when a tag contains HTML attributes and hash attributes' do
    let(:haml) { '%tag(lang=en){ attr: value }' }

    it { should report_lint }
  end
end
