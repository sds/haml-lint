# frozen_string_literal: true

module HamlLint
  class Adapter
    # Adapts the Haml::Parser from Haml 6 for use in HamlLint
    # :reek:UncommunicativeModuleName
    class Haml6 < Adapter
      # Parses the specified Haml code into an abstract syntax tree
      #
      # @example
      #   HamlLint::Adapter::Haml6.new('%div')
      #
      # @api public
      # @param source [String] Haml code to parse
      # @param options [private Haml::Parser::ParserOptions]
      def initialize(source, options = {})
        @source = source
        @parser = Haml::Parser.new(options)
      end

      # Parses the source code into an abstract syntax tree
      #
      # @example
      #   HamlLint::Adapter::Haml6.new('%div').parse
      #
      # @api public
      # @return [Haml::Parser::ParseNode]
      # @raise [Haml::Error]
      def parse
        parser.call(source)
      end

      def precompile
        # Haml uses the filters as part of precompilation... we don't care about those,
        # but without this tweak, it would fail on filters that are not loaded.
        real_defined = Haml::Filters.registered
        Haml::Filters.instance_variable_set(:@registered, Hash.new { real_defined['plain'] })

        ::Haml::Engine.new.call(source)
      ensure
        Haml::Filters.instance_variable_set(:@registered, real_defined)
      end

      private

      # The Haml parser to adapt for HamlLint
      #
      # @api private
      # @return [Haml::Parser] the Haml 6 parser
      attr_reader :parser

      # The Haml code to parse
      #
      # @api private
      # @return [String] Haml code to parse
      attr_reader :source
    end
  end
end
