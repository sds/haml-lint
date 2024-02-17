# frozen_string_literal: true

module HamlLint
  # Checks for `id` attributes in specific cases on tags.
  class Linter::IdNames < Linter
    include LinterRegistry

    STYLIZED_NAMES = {
      'camel_case' => 'camelCase',
      'lisp_case' => 'lisp-case',
      'pascal_case' => 'PascalCase',
      'snake_case' => 'snake_case',
    }.freeze

    STYLES = {
      'camel_case' => /\A[a-z][\da-zA-Z]+\z/,
      'lisp_case' => /\A[\da-z-]+\z/,
      'pascal_case' => /\A[A-Z][\da-zA-Z]+\z/,
      'snake_case' => /\A[\da-z_]+\z/,
    }.freeze

    def visit_tag(node)
      return unless (id = node.tag_id)

      style = config['style'] || 'lisp_case'
      matcher = STYLES[style]
      record_lint(node, "`id` attribute must be in #{STYLIZED_NAMES[style]}") unless id&.match?(matcher)
    end
  end
end
