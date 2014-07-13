require 'find'

module HamlLint
  # A miscellaneous set of utility functions.
  module Utils
    class << self
      def extract_files_from(list)
        files = []
        list.each do |file|
          Find.find(file) do |f|
            files << f if haml_file?(f)
          end
        end
        files.uniq
      end

    private

      def haml_file?(file)
        return false unless FileTest.file?(file)

        File.extname(file) == '.haml'
      end
    end
  end
end
