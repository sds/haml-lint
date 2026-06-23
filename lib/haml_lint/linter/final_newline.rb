# frozen_string_literal: true

module HamlLint
  # Checks for final newlines at the end of a file.
  class Linter::FinalNewline < Linter
    include LinterRegistry

    supports_autocorrect(true)

    # Run last during autocorrect, so any line-level corrections from other
    # linters are applied before the trailing newline is normalized.
    autocorrect_priority(1)

    def visit_root(root)
      return if document.source.empty?
      line_number = document.last_non_empty_line

      node = root.node_for_line(line_number)
      return if node.disabled?(self)

      present = config['present'] ? true : false
      corrected = corrected_source(present)
      return if document.source == corrected

      record_lint(line_number, message_for(present), corrected: autocorrect?)
      apply_autocorrect(corrected)
    end

    private

    def message_for(present)
      if present
        'Files should end with a trailing newline'
      else
        'Files should not end with a trailing newline'
      end
    end

    # Normalizes only the single final newline. Collapsing multiple trailing
    # newlines is `TrailingEmptyLines`' job, so a file that already ends with a
    # newline is left untouched here under `present`.
    def corrected_source(present)
      if present
        document.source.end_with?("\n") ? document.source : "#{document.source}\n"
      else
        document.source.sub(/\n+\z/, '')
      end
    end
  end
end
