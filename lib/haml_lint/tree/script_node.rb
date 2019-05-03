# frozen_string_literal: true

require 'haml_lint/parsed_ruby'

module HamlLint::Tree
  # Represents a node which produces output based on Ruby code.
  class ScriptNode < Node
    # The Ruby script contents parsed into a syntax tree.
    #
    # @return [ParsedRuby] syntax tree in the form returned by Parser gem
    def parsed_script
      HamlLint::ParsedRuby.new(HamlLint::RubyParser.new.parse(script))
    end

    # Returns the source for the script following the `-` marker.
    #
    # @return [String]
    def script
      @value[:text]
    end
  end
end
