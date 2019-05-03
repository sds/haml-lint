# frozen_string_literal: true

module HamlLint
  # A catch-all linter for syntax violations raised by the Haml parser.
  class Linter::Syntax < Linter
    include LinterRegistry
  end
end
