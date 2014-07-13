module HamlLint
  class NoSuchLinter < StandardError; end

  # Stores all defined linters.
  module LinterRegistry
    @linters = []

    class << self
      attr_reader :linters

      def included(base)
        @linters << base
      end

      def extract_linters_from(linter_names)
        linter_names.map do |linter_name|
          begin
            HamlLint::Linter.const_get(linter_name)
          rescue NameError
            raise NoSuchLinter.new("Linter #{linter_name} does not exist")
          end
        end
      end
    end
  end
end
