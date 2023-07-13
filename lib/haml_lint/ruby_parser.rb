# frozen_string_literal: true

require 'rubocop'
require 'rubocop/ast/builder'

module HamlLint
  # Parser for the Ruby language.
  #
  # This provides a convenient wrapper around the `parser` gem and the
  # Astrolabe integration (now built-in to RuboCop, so no longer called
  # Astrolabe) to go with it. It is intended to be used for linter
  # checks that require deep inspection of Ruby code.
  class RubyParser
    # Creates a reusable parser.
    def initialize
      require_parser
      @builder = ::RuboCop::AST::Builder.new
      @parser = ::Parser::CurrentRuby.new(@builder)
    end

    # Require the current parser version while suppressing the
    # compliancy warning for minor version differences.
    def require_parser
      prev = $VERBOSE
      $VERBOSE = nil
      require 'parser/current'
    ensure
      $VERBOSE = prev
    end

    # Parse the given Ruby source into an abstract syntax tree.
    #
    # @param source [String] Ruby source code
    # @return [Array] syntax tree in the form returned by Parser gem
    def parse(source)
      buffer = ::Parser::Source::Buffer.new('(string)')
      buffer.source = source

      @parser.reset
      @parser.parse(buffer)
    end
  end
end
