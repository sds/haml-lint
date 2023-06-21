# frozen_string_literal: true

require 'forwardable'

module HamlLint
  class Adapter
    # Adapts the Haml::Parser from Haml 4 for use in HamlLint
    # :reek:UncommunicativeModuleName
    class Haml4 < Adapter
      extend Forwardable

      # Parses the specified Haml code into an abstract syntax tree
      #
      # @example
      #   HamlLint::Adapter::Haml4.new('%div')
      #
      # @api public
      # @param source [String] Haml code to parse
      # @param options [Haml::Options]
      def initialize(source, options = Haml::Options.new)
        @source = source
        @parser = Haml::Parser.new(source, options)
      end

      def precompile
        # Haml uses the filters as part of precompilation... we don't care about those,
        # but without this tweak, it would fail on filters that are not loaded.
        real_defined = Haml::Filters.defined
        Haml::Filters.instance_variable_set(:@defined, Hash.new { real_defined['plain'] })

        ::Haml::Engine.new(source).precompiled
      ensure
        Haml::Filters.instance_variable_set(:@defined, real_defined)
      end

      # @!method
      #   Parses the source code into an abstract syntax tree
      #
      #   @example
      #     HamlLint::Adapter::Haml4.new('%div')
      #
      #   @api public
      #   @return [Haml::Parser::ParseNode]
      # @raise [Haml::Error]
      def_delegator :parser, :parse

      private

      # The Haml parser to adapt for HamlLint
      #
      # @api private
      # @return [Haml::Parser] the Haml 4 parser
      attr_reader :parser

      # The Haml code to parse
      #
      # @api private
      # @return [String] Haml code to parse
      attr_reader :source
    end
  end
end
