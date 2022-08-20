# frozen_string_literal: true

module HamlLint::Tree
  # Represents a HAML silent script node (`- some_expression`) which executes
  # code without producing output.
  class SilentScriptNode < Node
    # The Ruby script contents parsed into a syntax tree.
    #
    # @return [ParsedRuby] syntax tree in the form returned by Parser gem
    def parsed_script
      statement =
        case keyword = @value[:keyword]
        when 'else', 'elsif'
          'if 0;' + script + ';end'
        when 'when'
          'case;' + script + ';end'
        when 'rescue', 'ensure'
          'begin;' + script + ';end'
        else
          if children.empty?
            script
          else
            "#{script}#{keyword == 'case' ? ';when 0;end' : ';end'}"
          end
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
