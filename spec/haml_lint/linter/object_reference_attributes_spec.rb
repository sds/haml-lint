describe HamlLint::Linter::ObjectReferenceAttributes do
  include_context 'linter'

  context 'when a tag has no attributes' do
    let(:haml) { '%tag' }

    it { should_not report_lint }
  end

  context 'when a tag contains hash attributes' do
    let(:haml) { "%tag{ lang: 'en' }" }

    it { should_not report_lint }
  end

  context 'when a tag contains an object reference' do
    let(:haml) { '%tag[@user]' }

    it { should report_lint }
  end

  context 'when a tag has an object reference with nil inside' do
    let(:haml) { '%tag[nil]' }

    it { should report_lint }
  end
end
