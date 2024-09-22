# frozen_string_literal: true

require_relative 'adapter/haml_5'
require_relative 'adapter/haml_6'
require_relative 'exceptions'

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
      when '~> 5.0', '~> 5.1', '~> 5.2' then HamlLint::Adapter::Haml5
      when '~> 6.0', '~> 6.0.a', '~> 6.1', '~> 6.2', '~> 6.3' then HamlLint::Adapter::Haml6
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
