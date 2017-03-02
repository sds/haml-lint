module HamlLint::Tree
  # Represents the root node of a HAML document that contains all other nodes.
  class RootNode < Node
    # The name fo the file parsed to build this tree.
    #
    # @return [String] a file name
    def file
      @document.file
    end
  end
end
