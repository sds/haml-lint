module HamlLint::Tree
  # Decorator class that provides a convenient set of helpers for HAML's
  # {Haml::Parser::ParseNode} struct.
  #
  # The goal is to abstract away the details of the underlying struct and
  # provide a cleaner and more uniform interface for getting information about a
  # node, as there are a number of weird/special cases in the struct returned by
  # the HAML parser.
  #
  # @abstract
  class Node
    attr_accessor :children
    attr_reader :line, :parent, :type

    # Creates a node wrapping the given {Haml::Parser::ParseNode} struct.
    #
    # @param parser [HamlLint::Parser] parser that created this node
    # @param parse_node [Haml::Parser::ParseNode] parse node created by HAML's parser
    # @param parent [HamlLint::Tree::Node] parent of this node
    def initialize(parser, parse_node, parent)
      # TODO: Change signature to take source code object, not parser
      @line = parse_node.line
      @parent = parent
      @parser = parser
      @value = parse_node.value
      @type = parse_node.type
    end

    # Source code of the first line of this node.
    #
    # @return [String]
    def first_line_source
      @parser.lines[@line - 1]
    end

    # Returns the text content of this node.
    #
    # @return [String]
    def text
      @value[:text].to_s
    end
  end
end
