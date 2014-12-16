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
    attr_accessor :children, :parent
    attr_reader :line, :type

    # Creates a node wrapping the given {Haml::Parser::ParseNode} struct.
    #
    # @param parser [HamlLint::Parser] parser that created this node
    # @param parse_node [Haml::Parser::ParseNode] parse node created by HAML's parser
    def initialize(parser, parse_node)
      # TODO: Change signature to take source code object, not parser
      @line = parse_node.line
      @parser = parser
      @value = parse_node.value
      @type = parse_node.type
    end

    # Returns the first node found under the subtree which matches the given
    # block.
    #
    # Returns nil if no node matching the given block was found.
    #
    # @return [HamlLint::Tree::Node,nil]
    def find(&block)
      return self if block.call(self)

      children.each do |child|
        if result = child.find(&block)
          return result
        end
      end

      nil # Otherwise no matching node was found
    end

    # Source code of the first line of this node.
    #
    # @return [String]
    def first_line_source
      @parser.lines[@line - 1]
    end

    # Source code of all lines this node spans (excluding children).
    #
    # @return [String]
    def source_code
      next_node_line =
        if next_node
          next_node.line - 1
        else
          @parser.lines.count + 1
        end

      @parser.lines[@line - 1...next_node_line]
             .join("\n")
             .gsub(/^\s*\z/m, '') # Remove blank lines at the end
    end

    def inspect
      "#<#{self.class.name}>"
    end

    # Returns the node that follows this node, whether it be a sibling or an
    # ancestor's child, but not a child of this node.
    #
    # If you are also willing to return the child, call {#next_node}.
    #
    # Returns nil if there is no successor.
    #
    # @return [HamlLint::Tree::Node,nil]
    def successor
      siblings = parent ? parent.children : [self]

      next_sibling = siblings[siblings.index(self) + 1] if siblings.count > 1
      return next_sibling if next_sibling

      parent.successor if parent
    end

    # Returns the next node that appears after this node in the document.
    #
    # Returns nil if there is no next node.
    #
    # @return [HamlLint::Tree::Node,nil]
    def next_node
      children.first || successor
    end

    # Returns the text content of this node.
    #
    # @return [String]
    def text
      @value[:text].to_s
    end
  end
end
