require 'pathname'
require 'yaml'

module HamlLint
  # Manages configuration file loading.
  class ConfigurationLoader
    DEFAULT_CONFIG_PATH = File.join(HAML_LINT_HOME, 'config', 'default.yml')
    CONFIG_FILE_NAME = '.haml-lint.yml'

    def self.load_applicable_config
      directory = File.expand_path(Dir.pwd)
      config_file = possible_config_files(directory).find { |path| path.file? }

      if config_file
        load_file(config_file.to_path)
      else
        default_configuration
      end
    end

    def self.default_configuration
      @default_config ||= load_from_file(DEFAULT_CONFIG_PATH)
    end

  private

    # Loads a configuration, ensuring it extends the default configuration.
    def self.load_file(file)
      config = load_from_file(file)

      default_configuration.merge(config)
    rescue => error
      raise HamlLint::Exceptions::ConfigurationError,
            "Unable to load configuration from '#{file}': #{error}",
            error.backtrace
    end

    def self.load_from_file(file)
      hash =
        if yaml = YAML.load_file(file)
          yaml.to_hash
        else
          {}
        end

      HamlLint::Configuration.new(hash)
    end

    def self.possible_config_files(directory)
      files = Pathname.new(directory)
                      .enum_for(:ascend)
                      .map { |path| path + CONFIG_FILE_NAME }
      files << Pathname.new(CONFIG_FILE_NAME)
    end
  end
end
