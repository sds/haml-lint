# frozen_string_literal: true

module HamlLint
  class Adapter
    # Adapts the Haml::Parser from Haml 5 for use in HamlLint
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
