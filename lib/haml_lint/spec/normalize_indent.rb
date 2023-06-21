# frozen_string_literal: true

module HamlLint
  module Spec
    # Strips off excess leading indentation from each line so we can use Heredocs
    # for writing code without having the leading indentation count.
    module IndentNormalizer
      def normalize_indent(code)
        leading_indent = code[/([ \t]*)/, 1]
        code.gsub(/^#{leading_indent}/, '')
      end
    end
  end
end

RSpec.configure do |_config|
  include HamlLint::Spec::IndentNormalizer
end
