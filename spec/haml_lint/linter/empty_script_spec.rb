describe HamlLint::Linter::EmptyScript do
  include_context 'linter'

  context 'when silent script contains code' do
    let(:haml) { '- some_expression' }

    it { should_not report_lint }
  end

  context 'when silent script contains no code' do
    let(:haml) { '-' }

    it { should report_lint }
  end
end
