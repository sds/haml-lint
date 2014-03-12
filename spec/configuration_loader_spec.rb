require 'spec_helper'

describe HamlLint::ConfigurationLoader do
  describe '.load_applicable_config' do
    subject { described_class.load_applicable_config }

    context 'when directory does not contain a configuration file' do
      around do |example|
        directory { example.run }
      end

      it 'returns the default configuration' do
        subject.should == described_class.default_configuration
      end
    end

    context 'when directory contains a configuration file' do
      let(:config_contents) { <<-CFG }
        linters:
          ALL:
            enabled: false
      CFG

      around do |example|
        directory do
          File.open('.haml-lint.yml', 'w') { |f| f.write(config_contents) }
          example.run
        end
      end

      it 'loads the file' do
        described_class.should_receive(:load_file)
                       .with(File.expand_path('.haml-lint.yml'))
        subject
      end

      it 'merges the loaded file with the default configuration' do
        subject.should_not == described_class.default_configuration
      end
    end
  end
end
