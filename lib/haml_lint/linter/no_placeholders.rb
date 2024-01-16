# frozen_string_literal: true

module HamlLint
  # Checks that placeholder attributes are not used.
  class Linter::NoPlaceholders < Linter
    include LinterRegistry

    MSG = 'Placeholders attributes should not be used.'
    HASH_REGEXP = /:?['"]?placeholder['"]?(?::| *=>)/
    HTML_REGEXP = /placeholder=/

    def visit_tag(node)
      return unless node.hash_attributes_source =~ HASH_REGEXP || node.html_attributes_source =~ HTML_REGEXP

      record_lint(node, MSG)
    end
  end
end
