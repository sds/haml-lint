RSpec.describe HamlLint::Linter::AlignmentTabs do
  include_context 'linter'

  context 'when there are no non-indentation tabs' do
    let(:haml) { '%p Hello' }

    it { should_not report_lint }

    context 'even in a multiline tag that uses tabs for indentation' do
      let(:haml) { "%p\n\t%span Hello\n\t%span world" }

      it { should_not report_lint }
    end
  end

  context 'when there are non-indentation tabs' do
    let(:haml) { "%p\tHello" }

    it { should report_lint }

    context 'in a multiline tag that uses tabs for indentation' do
      let(:haml) { "%p\n\t%span Hello\n\t%span\tworld" }

      it { should report_lint line: 3 }
    end
  end
end
