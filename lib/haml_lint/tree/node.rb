# frozen_string_literal: true

require_relative '../comment_configuration'

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
    include Enumerable

    attr_accessor :children, :parent
    attr_reader :line, :type

    # Creates a node wrapping the given {Haml::Parser::ParseNode} struct.
    #
    # @param document [HamlLint::Document] Haml document that created this node
    # @param parse_node [Haml::Parser::ParseNode] parse node created by HAML's parser
    def initialize(document, parse_node)
      @line = parse_node.line
      @document = document
      @value = parse_node.value
      @type = parse_node.type
    end

    # Holds any configuration that is created from Haml comments.
    #
    # @return [HamlLint::CommentConfiguration]
    def comment_configuration
      @comment_configuration ||= HamlLint::CommentConfiguration.new(self)
    end

    # Checks whether a visitor is disabled due to comment configuration.
    #
    # @param [HamlLint::HamlVisitor]
    # @return [true, false]
    def disabled?(visitor)
      visitor.is_a?(HamlLint::Linter) &&
        comment_configuration.disabled?(visitor.name)
    end

    # Implements the Enumerable interface to walk through an entire tree.
    #
    # @return [Enumerator, HamlLint::Tree::Node]
    def each
      return to_enum(__callee__) unless block_given?

      node = self
      loop do
        yield node
        break unless (node = node.next_node)
      end
    end

    # The comment directives to apply to the node.
    #
    # @return [Array<HamlLint::Directive>]
    def directives
      directives = []
      directives << predecessor.directives if predecessor
      directives.flatten
    end

    # Source code of all lines this node spans (excluding children).
    #
    # @return [String]
    def source_code
      next_node_line =
        if next_node
          next_node.line - 1
        else
          @document.source_lines.count + 1
        end

      @document.source_lines[@line - 1...next_node_line]
               .join("\n")
               .gsub(/^\s*\z/m, '') # Remove blank lines at the end
    end

    def inspect
      "#<#{self.class.name}>"
    end

    # The lines of text, if any, that are contained in the node.
    #
    # @api public
    # @return [Array<String>]
    def lines
      return [] unless @value && text

      text.split(/\r\n|\r|\n/)
    end

    # The line numbers that are contained within the node.
    #
    # @api public
    # @return [Range]
    def line_numbers
      return (line..line) unless @value && text

      end_line = if !lines.empty?
                   line + lines.count - 1
                 elsif children.empty?
                   nontrivial_end_line
                 else
                   line
                 end

      (line..end_line)
    end

    # The previous node to be traversed in the tree.
    #
    # @return [HamlLint::Tree::Node, nil]
    def predecessor
      siblings.previous(self) || parent
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
      next_sibling = siblings.next(self)
      return next_sibling if next_sibling

      parent&.successor
    end

    # Returns the next node that appears after this node in the document.
    #
    # Returns nil if there is no next node.
    #
    # @return [HamlLint::Tree::Node,nil]
    def next_node
      children.first || successor
    end

    # The sibling nodes that come after this node in the tree.
    #
    # @return [Array<HamlLint::Tree::Node>]
    def subsequents
      siblings.subsequents(self)
    end

    # Returns the text content of this node.
    #
    # @return [String]
    def text
      @value[:text].to_s
    end

    def keyword
      @value[:keyword]
    end

    private

    # Discovers the end line of the node when there are no lines.
    #
    # @return [Integer] the end line of the node
    def nontrivial_end_line
      if successor
        successor.line_numbers.begin - 1
      else
        @document.last_non_empty_line
      end
    end

    # The siblings of this node within the tree.
    #
    # @api private
    # @return [Array<HamlLint::Tree::Node>]
    def siblings
      @siblings ||= Siblings.new(parent ? parent.children : [self])
    end

    # Finds the node's siblings within the tree and makes them queryable.
    class Siblings < SimpleDelegator
      # Finds the next sibling in the tree for a given node.
      #
      # @param node [HamlLint::Tree::Node]
      # @return [HamlLint::Tree::Node, nil]
      def next(node)
        subsequents(node).first
      end

      # Finds the previous sibling in the tree for a given node.
      #
      # @param node [HamlLint::Tree::Node]
      # @return [HamlLint::Tree::Node, nil]
      def previous(node)
        priors(node).last
      end

      # Finds all sibling notes that appear before a node in the tree.
      #
      # @param node [HamlLint::Tree::Node]
      # @return [Array<HamlLint::Tree::Node>]
      def priors(node)
        position = position(node)
        if position.zero?
          []
        else
          siblings[0..(position - 1)]
        end
      end

      # Finds all sibling notes that appear after a node in the tree.
      #
      # @param node [HamlLint::Tree::Node]
      # @return [Array<HamlLint::Tree::Node>]
      def subsequents(node)
        siblings[(position(node) + 1)..]
      end

      private

      # The set of siblings within the tree.
      #
      # @api private
      # @return [Array<HamlLint::Tree::Node>]
      alias siblings __getobj__

      # Finds the position of a node within a set of siblings.
      #
      # @api private
      # @return [Integer, nil]
      def position(node)
        siblings.index(node)
      end
    end
  end
end
