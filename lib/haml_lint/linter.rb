module HamlLint
  class Linter
    attr_reader :parser, :lints

    def initialize
      @lints = []
    end

    def run(parser)
      @parser = parser
      visit(parser.tree)
    end

    def message
      nil # Subclasses can implement if they want a default lint message
    end

  protected

    def add_lint(node, message = nil)
      @lints << Lint.new(parser.filename, node.line, message || self.message)
    end

  private

    def visit(node)
      method = "visit_#{node_name node}"

      # Keep track of whether this block was consumed by the visitor. This
      # allows us to visit all nodes by default, but can override the behaviour
      # by specifying `yield false` in a visit method, indicating that no
      # further visiting should occur for the current node's children.
      block_called = false

      block = ->(continue = nil) do
        block_called = true
        visit_children(node) unless continue == false
      end

      send(method, node, &block) if respond_to?(method, true)

      # Visit all children by default unless the block was invoked (indicating
      # the user intends to not recurse further, or wanted full control over
      # when the children were visited).
      visit_children(node) unless block_called
    end

    def visit_children(parent)
      parent.children.each { |node| visit(node) }
    end

    def node_name(node)
      node.type
    end
  end
end
