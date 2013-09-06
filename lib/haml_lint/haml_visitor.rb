module HamlLint
  module HamlVisitor
    def visit(node)
      # Keep track of whether this block was consumed by the visitor. This
      # allows us to visit all nodes by default, but can override the behaviour
      # by specifying `yield false` in a visit method, indicating that no
      # further visiting should occur for the current node's children.
      block_called = false

      block = ->(continue = :children) do
        block_called = true
        visit_children(node) if continue == :children
      end

      method = "visit_#{node_name(node)}"
      send(method, node, &block) if respond_to?(method, true)

      # Visit all children by default unless the block was invoked (indicating
      # the user intends to not recurse further, or wanted full control over
      # when the children were visited).
      visit_children(node) unless block_called
    end

    def visit_children(parent)
      parent.children.each { |node| visit(node) }
    end

  private

    def node_name(node)
      node.type
    end
  end
end
