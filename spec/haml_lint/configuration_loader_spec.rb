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

    context 'with an "inherits_from" directive' do
      let(:config_file) do
        [
          "inherits_from: #{other_config}",
          'skip_frontmatter: true',
          'linters:',
          '  AltText:',
          '    enabled: true'
        ].join("\n")
      end
      let(:other_config) { 'other_haml-lint.yml' }

      before do
        File.open(file_name, 'w') { |f| f.write(config_file) }
      end

      context 'for a file that does not exist' do
        it 'extends the default configuration' do
          custom_config = HamlLint::Configuration.new(
            'inherits_from' => other_config,
            'skip_frontmatter' => true,
            'linters' => {
              'AltText' => { 'enabled' => true }
            }
          )

          subject.should ==
            described_class.default_configuration.merge(custom_config)
        end
      end

      context 'for a file that exists' do
        let(:other_config_file) do
          [
            'linters:',
            '  AltText:',
            '    enabled: false',
            '  Indentation:',
            '    enabled: false'
          ].join("\n")
        end

        before do
          File.open(other_config, 'w') { |f| f.write(other_config_file) }
        end

        it 'layers the inherited config on the default with the main file overriding both' do
          custom_config = HamlLint::Configuration.new(
            'inherits_from' => other_config,
            'skip_frontmatter' => true,
            'linters' => {
              'AltText' => { 'enabled' => true },
              'Indentation' => { 'enabled' => false }
            }
          )

          subject.should ==
            described_class.default_configuration.merge(custom_config)
        end

        context 'when the file has a circular dependency on another' do
          let(:other_config_file) do
            [
              "inherits_from: #{file_name}",
              'linters:',
              '  AltText:',
              '    enabled: false',
              '  Indentation:',
              '    enabled: false'
            ].join("\n")
          end

          it 'loads each file once and does not start an endless loop' do
            custom_config = HamlLint::Configuration.new(
              'inherits_from' => other_config,
              'skip_frontmatter' => true,
              'linters' => {
                'AltText' => { 'enabled' => true },
                'Indentation' => { 'enabled' => false }
              }
            )

            subject.should ==
              described_class.default_configuration.merge(custom_config)
          end
        end

        context 'with multiple files' do
          let(:config_file) do
            [
              'inherits_from:',
              "  - #{other_config}",
              "  - #{third_config}",
              'skip_frontmatter: true',
              'linters:',
              '  AltText:',
              '    enabled: true'
            ].join("\n")
          end
          let(:other_config_file) do
            [
              'linters:',
              '  AltText:',
              '    enabled: false',
              '  Indentation:',
              '    enabled: false'
            ].join("\n")
          end
          let(:third_config) { 'other.yml' }
          let(:third_config_file) do
            [
              'linters:',
              '  AltText:',
              '    enabled: true',
              '  Indentation:',
              '    enabled: true'
            ].join("\n")
          end

          before do
            File.open(third_config, 'w') { |f| f.write(third_config_file) }
          end

          it 'loads them all in the correct order' do
            custom_config = HamlLint::Configuration.new(
              'inherits_from' => [other_config, third_config],
              'skip_frontmatter' => true,
              'linters' => {
                'AltText' => { 'enabled' => true },
                'Indentation' => { 'enabled' => true }
              }
            )

            subject.should ==
              described_class.default_configuration.merge(custom_config)
          end
        end

        context 'and an inherit_from directive' do
          let(:config_file) do
            [
              'inherits_from:',
              "  - #{other_config}",
              'inherit_from:',
              "  - #{third_config}",
              'skip_frontmatter: true',
              'linters:',
              '  AltText:',
              '    enabled: true'
            ].join("\n")
          end
          let(:other_config_file) do
            [
              'linters:',
              '  AltText:',
              '    enabled: false',
              '  Indentation:',
              '    enabled: false'
            ].join("\n")
          end
          let(:third_config) { 'other.yml' }
          let(:third_config_file) do
            [
              'linters:',
              '  AltText:',
              '    enabled: true',
              '  Indentation:',
              '    enabled: true'
            ].join("\n")
          end

          before do
            File.open(third_config, 'w') { |f| f.write(third_config_file) }
          end

          it 'combines the inherit_from directive with the inherits_from directive' do
            custom_config = HamlLint::Configuration.new(
              'inherits_from' => [other_config, third_config],
              'skip_frontmatter' => true,
              'linters' => {
                'AltText' => { 'enabled' => true },
                'Indentation' => { 'enabled' => true }
              }
            )

            subject.should ==
              described_class.default_configuration.merge(custom_config)
          end
        end
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
        subject.should == described_class.default_configuration
                          .merge(HamlLint::Configuration.new(hash))
      end
    end
  end
end
