require 'spec_helper'

RSpec.describe HamlLint::Directive do
  subject(:directive) { described_class.new }

  describe '.from_line' do
    let(:line) { 1 }

    subject(:directive) { described_class.from_line(source, line) }

    context 'for a line that is a directive' do
      let(:source) { ' haml-lint:disable AltText, LineLength' }

      describe '#disable?' do
        subject { directive.disable? }

        it { is_expected.to eq(true) }
      end

      describe '#enable?' do
        subject { directive.enable? }

        it { is_expected.to eq(false) }
      end

      describe '#linters' do
        subject { directive.linters }

        it { is_expected.to eq(%w[AltText LineLength]) }
      end

      describe '#inspect' do
        subject { directive.inspect }

        it { is_expected.to match(/mode=disable, linters=\["AltText", "LineLength"\]/) }
      end
    end

    context 'for a line that is not a directive' do
      let(:source) { 'Disable these linters' }

      describe '#disable?' do
        subject { directive.disable? }

        it { is_expected.to eq(false) }
      end

      describe '#enable?' do
        subject { directive.enable? }

        it { is_expected.to eq(false) }
      end

      describe '#linters' do
        subject { directive.linters }

        it { is_expected.to eq([]) }
      end

      describe '#inspect' do
        subject { directive.inspect }

        it { is_expected.to eq('#<HamlLint::Directive::Null>') }
      end
    end
  end
end
