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

  describe '.default_configuration' do
    subject { described_class.default_configuration }

    before do
      # Ensure cache is cleared
      described_class.instance_variable_set(:@default_config, nil)
    end

    it 'loads the default config file' do
      described_class.should_receive(:load_from_file)
        .with(HamlLint::ConfigurationLoader::DEFAULT_CONFIG_PATH)
      subject
    end
  end

  describe '.load_file' do
    let(:file_name) { 'config.yml' }
    subject { described_class.load_file(file_name) }

    around do |example|
      directory { example.run }
    end

    context 'with a file that exists' do
      before do
        File.open(file_name, 'w') { |f| f.write(config_file) }
      end

      context 'and is empty' do
        let(:config_file) { '' }

        it 'is equivalent to the default configuration' do
          subject.should == described_class.default_configuration
        end
      end

      context 'and is valid' do
        let(:config_file) { 'skip_frontmatter: true' }

        it 'loads the custom configuration' do
          subject['skip_frontmatter'].should == true
        end

        it 'extends the default configuration' do
          custom_config = HamlLint::Configuration.new('skip_frontmatter' => true)

          subject.should ==
            described_class.default_configuration.merge(custom_config)
        end
      end

      context 'and is invalid' do
        let(:config_file) { normalize_indent(<<-CONF) }
          linters:
            SomeLinter:
            invalid
        CONF

        it 'raises an error' do
          expect { subject }.to raise_error HamlLint::Exceptions::ConfigurationError
        end
      end
    end

    context 'with a file that does not exist' do
      it 'raises an error' do
        expect { subject }.to raise_error HamlLint::Exceptions::ConfigurationError
      end
    end
  end

  describe '.load_hash' do
    subject { described_class.load_hash(hash) }

    context 'when hash is empty' do
      let(:hash) { {} }

      it 'is equivalent to the default configuration' do
        subject.should == described_class.default_configuration
      end
    end

    context 'when hash is not empty' do
      let(:hash) { { 'skip_frontmatter' => true } }

      it 'extends the default configuration' do
        subject.should ==
          described_class.default_configuration
                         .merge(HamlLint::Configuration.new(hash))
      end
    end
  end
end
