# frozen_string_literal: true

require_relative '../parsed_ruby'

module HamlLint::Tree
  # Represents a node which produces output based on Ruby code.
  class ScriptNode < Node
    # The Ruby script contents parsed into a syntax tree.
    #
    # @return [ParsedRuby] syntax tree in the form returned by Parser gem
    def parsed_script
      statement =
        if children.empty?
          script
        else
          "#{script}#{@value[:keyword] == 'case' ? ';when 0;end' : ';end'}"
        end
      HamlLint::ParsedRuby.new(HamlLint::RubyParser.new.parse(statement))
    end

    # Returns the source for the script following the `-` marker.
    #
    # @return [String]
    def script
      @value[:text]
    end
  end
end
