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
      when Gem::Requirement.new('~> 5.0') then HamlLint::Adapter::Haml5
      when Gem::Requirement.new('>= 6.0.a') then HamlLint::Adapter::Haml6
      else fail HamlLint::Exceptions::UnknownHamlVersion, "Cannot handle Haml version: #{version}"
      end
    end

    # Determines the version of Haml that is installed
    #
    # @api private
    # @return [Gem::Version] the Haml version
    def self.haml_version
      Gem::Version.new(Haml::VERSION)
    end
    private_class_method :haml_version
  end
end
