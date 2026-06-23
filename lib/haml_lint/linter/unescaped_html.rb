# frozen_string_literal: true

module HamlLint
  # Flags Haml's unescaped-output markers (`!=`, `!~`, and the unescaped
  # plain-text `!`), which bypass HTML escaping.
  #
  # Like `raw`, `html_safe`, and `h()` in Rails, these make it easy to
  # accidentally introduce XSS vulnerabilities when the output includes
  # user-controlled data, e.g.:
  #
  #   != "Username: <strong>#{user.name}</strong>"
  class Linter::UnescapedHtml < Linter
    include LinterRegistry

    MESSAGE =
      'Avoid outputting unescaped HTML with `!`; it bypasses HTML escaping and ' \
      'can introduce XSS vulnerabilities. Sanitize the value instead.'

    def visit_script(node)
      record_lint(node, MESSAGE) if /\A\s*!/.match?(node.source_code)
    end

    def visit_tag(node)
      record_lint(node, MESSAGE) if node.unescape_html?
    end
  end
end
