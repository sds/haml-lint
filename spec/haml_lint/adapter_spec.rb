# frozen_string_literal: true

RSpec.describe HamlLint::Adapter do
  describe '.detect_class' do
    subject { described_class.detect_class }

    context 'on Haml 4' do
      before { stub_const('Haml::VERSION', '4.0.7') }

      it { should == HamlLint::Adapter::Haml4 }
    end

    context 'on Haml 5' do
      before { stub_const('Haml::VERSION', '5.0.0') }

      it { should == HamlLint::Adapter::Haml5 }
    end

    context 'on unknown version of Haml' do
      before { stub_const('Haml::VERSION', '3.0.0') }

      it 'raises an error' do
        expect { subject }.to raise_error(HamlLint::Exceptions::UnknownHamlVersion)
      end
    end
  end
end
