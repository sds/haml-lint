describe HamlLint::LinterRegistry do
  context 'when including the LinterRegistry module' do
    it 'adds the linter to the set of registered linters' do
      expect do
        class FakeLinter < HamlLint::Linter
          include HamlLint::LinterRegistry
        end
      end.to change { HamlLint::LinterRegistry.linters.count }.by(1)
    end
  end

  describe '.extract_linters_from' do
    module HamlLint
      class Linter::SomeLinter < Linter; include LinterRegistry; end
      class Linter::SomeOtherLinter < Linter::SomeLinter; end
    end
    let(:linters) do
      [HamlLint::Linter::SomeLinter, HamlLint::Linter::SomeOtherLinter]
    end

    context 'when the linters exist' do
      let(:linter_names) { %w[SomeLinter SomeOtherLinter] }

      it 'returns the linters' do
        subject.extract_linters_from(linter_names).should == linters
      end
    end

    context "when the linters don't exist" do
      let(:linter_names) { ['SomeRandomLinter'] }

      it 'raises an error' do
        expect do
          subject.extract_linters_from(linter_names)
        end.to raise_error(HamlLint::NoSuchLinter)
      end
    end
  end
end
