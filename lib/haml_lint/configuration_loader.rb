# frozen_string_literal: true

require 'pathname'
require 'yaml'

module HamlLint
  # Manages configuration file loading.
  class ConfigurationLoader
    DEFAULT_CONFIG_PATH = File.join(HamlLint::HOME, 'config', 'default.yml').freeze
    CONFIG_FILE_NAME = '.haml-lint.yml'.freeze

    class << self
      # Load configuration file given the current working directory the
      # application is running within.
      def load_applicable_config
        directory = File.expand_path(Dir.pwd)
        config_file = possible_config_files(directory).find(&:file?)

        if config_file
          load_file(config_file.to_path)
        else
          default_configuration
        end
      end

      # Loads the built-in default configuration.
      def default_configuration
        @default_config ||= load_from_file(DEFAULT_CONFIG_PATH)
      end

      # Loads a configuration, ensuring it extends the default configuration.
      #
      # @param file [String]
      # @param loaded_files [Array<String>] any previously loaded files in an
      #   inheritance chain
      # @return [HamlLint::Configuration]
      def load_file(file, loaded_files = [])
        config = load_from_file(file)

        [default_configuration, resolve_inheritance(config, loaded_files), config]
          .reduce { |acc, elem| acc.merge(elem) }
      rescue Psych::SyntaxError, Errno::ENOENT => error
        raise HamlLint::Exceptions::ConfigurationError,
              "Unable to load configuration from '#{file}': #{error}",
              error.backtrace
      end

      # Creates a configuration from the specified hash, ensuring it extends the
      # default configuration.
      #
      # @param hash [Hash]
      # @return [HamlLint::Configuration]
      def load_hash(hash)
        config = HamlLint::Configuration.new(hash)

        default_configuration.merge(config)
      end

      private

      # Parses and loads a configuration from the given file.
      #
      # @param file [String]
      # @return [HamlLint::Configuration]
      def load_from_file(file)
        hash =
          if yaml = YAML.load_file(file)
            yaml.to_hash
          else
            {}
          end

        if hash.key?('inherit_from')
          hash['inherits_from'] ||= []
          hash['inherits_from'].concat(Array(hash.delete('inherit_from')))
        end

        HamlLint::Configuration.new(hash)
      end

      # Returns a list of possible configuration files given the context of the
      # specified directory.
      #
      # @param directory [String]
      # @return [Array<Pathname>]
      def possible_config_files(directory)
        files = Pathname.new(directory)
                        .enum_for(:ascend)
                        .map { |path| path + CONFIG_FILE_NAME }
        files << Pathname.new(CONFIG_FILE_NAME)
      end

      # Resolves an inherited file and loads it.
      #
      # @param file [String] the path to the file
      # @param loaded_files [Array<String>] previously loaded files in the
      #   inheritance chain
      # @return [HamlLint::Configuration, nil]
      def resolve(file, loaded_files)
        return unless File.exist?(file)
        return if loaded_files.include?(file)

        loaded_files << file
        load_file(file, loaded_files)
      end

      # Resolves the chain of `inherits_from` directives in a configuration.
      #
      # @param config [HamlLint::Configuration] the pre-existing configuration
      # @param loaded_files [Array<String>] any previously loaded files in an
      #   inheritance chain
      # @return [HamlLint::Configuration]
      def resolve_inheritance(config, loaded_files)
        Array(config['inherits_from'])
          .map { |config_file| resolve(config_file, loaded_files) }
          .compact
          .reduce { |acc, elem| acc.merge(elem) } || config
      end
    end
  end
end
