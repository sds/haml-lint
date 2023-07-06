# frozen_string_literal: true

module HamlLint
  # Detects repeated instances of an element ID in a file
  class Linter::RepeatedId < Linter
    include LinterRegistry

    MESSAGE_FORMAT = %{Do not repeat id "#%s" on the page}

    def visit_root(_node)
      @id_map = {}
    end

    def visit_tag(node)
      id = node.tag_id
      return unless id && !id.empty?

      id_map[id] ||= []
      nodes = (id_map[id] << node)
      case nodes.size
      when 1 then nil
      when 2 then add_lints_for_first_duplications(nodes)
      else add_lint(node, id)
      end
    end

    private

    attr_reader :id_map

    def add_lint(node, id)
      record_lint(node, MESSAGE_FORMAT % id)
    end

    def add_lints_for_first_duplications(nodes)
      nodes.each { |node| add_lint(node, node.tag_id) }
    end
  end
end
