require 'find'

module HamlLint
  # A miscellaneous set of utility functions.
  module Utils
    class << self
      def extract_files_from(list)
        files = []

        list.each do |file|
          begin
            Find.find(file) do |f|
              files << f if haml_file?(f)
            end
          rescue Errno::ENOENT
            # One of the paths specified does not exist; raise a more
            # descriptive exception so we know which one
            raise HamlLint::Exceptions::InvalidFilePath,
                  "File path '#{file}' does not exist"
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
