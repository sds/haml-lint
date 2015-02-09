require 'find'

module HamlLint
  # Finds HAML files that should be linted given a specified list of paths, glob
  # patterns, and configuration.
  class FileFinder
    # List of extensions of files to include under a directory when a directory
    # is specified instead of a file.
    VALID_EXTENSIONS = %w[.haml]

    # @param config [HamlLint::Configuration]
    def initialize(config)
      @config = config
    end

    # Return list of files to lint given the specified set of paths and glob
    # patterns.
    # @param patterns [Array<String>]
    # @param excluded_patterns [Array<String>]
    # @raise [HamlLint::Exceptions::InvalidFilePath]
    # @return [Array<String>] list of actual files
    def find(patterns, excluded_patterns)
      extract_files_from(patterns).reject do |file|
        excluded_patterns.any? do |exclusion_glob|
          ::File.fnmatch?(exclusion_glob, file,
                          ::File::FNM_PATHNAME | # Wildcards don't match path separators
                          ::File::FNM_DOTMATCH)  # `*` wildcard matches dotfiles
        end
      end
    end

    private

    def extract_files_from(patterns) # rubocop:disable MethodLength
      files = []

      patterns.each do |pattern|
        if File.file?(pattern)
          files << pattern
        else
          begin
            ::Find.find(pattern) do |file|
              files << file if haml_file?(file)
            end
          rescue ::Errno::ENOENT
            # File didn't exist; it might be a file glob pattern
            matches = ::Dir.glob(pattern)
            if matches.any?
              files += matches
            else
              # One of the paths specified does not exist; raise a more
              # descriptive exception so we know which one
              raise HamlLint::Exceptions::InvalidFilePath,
                    "File path '#{pattern}' does not exist"
            end
          end
        end
      end

      files.uniq
    end

    def haml_file?(file)
      return false unless ::FileTest.file?(file)

      VALID_EXTENSIONS.include?(::File.extname(file))
    end
  end
end
