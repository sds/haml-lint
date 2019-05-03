# frozen_string_literal: true

RSpec.describe HamlLint::Severity do
  let(:name) { nil }

  subject(:severity) { described_class.new(name) }

  it 'defaults to a warning' do
    subject.should == described_class.new(:warning)
  end

  it 'can be matched against a symbol severity' do
    subject.should == :warning
  end

  it 'ranks severities properly' do
    subject.should < described_class.new(:error)
  end

  it 'can wrap itself' do
    subject.should == described_class.new(subject)
  end

  describe '#error?' do
    subject { severity.error? }

    it { should == false }

    context 'for an error' do
      let(:name) { :error }

      it { should == true }
    end
  end

  describe '#warning?' do
    subject { severity.warning? }

    it { should == true }

    context 'for an error' do
      let(:name) { :error }

      it { should == false }
    end
  end
end
