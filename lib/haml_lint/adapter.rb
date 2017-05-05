require 'haml_lint/adapter/haml_4'
require 'haml_lint/adapter/haml_5'
require 'haml_lint/exceptions'

module HamlLint
  # Determines the adapter to use for the current Haml version
  class Adapter
    # Detects the adapter to use for the current Haml version
    #
    # @example
    #   HamlLint::Adapter.detect_class.new('%div')
    #
    # @api public
    # @return [Class] the adapter class
    # @raise [HamlLint::Exceptions::UnknownHamlVersion]
    def self.detect_class
      version = haml_version
      case version
      when '~> 4.0' then HamlLint::Adapter::Haml4
      when '~> 4.1' then HamlLint::Adapter::Haml4
      when '~> 5.0' then HamlLint::Adapter::Haml5
      else fail HamlLint::Exceptions::UnknownHamlVersion, "Cannot handle Haml version: #{version}"
      end
    end

    # Determines the approximate version of Haml that is installed
    #
    # @api private
    # @return [String] the approximate Haml version
    def self.haml_version
      Gem::Version
        .new(Haml::VERSION)
        .approximate_recommendation
    end
    private_class_method :haml_version
  end
end
