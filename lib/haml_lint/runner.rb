module HamlLint
  # Responsible for running the applicable linters against the desired files.
  class Runner
    # Runs the appropriate linters against the desired files given the specified
    # options.
    #
    # @param options [Hash]
    # @raise [HamlLint::Exceptions::NoLintersError] when no linters are enabled
    # @return [HamlLint::Report] a summary of all lints found
    def run(options = {})
      config = load_applicable_config(options)
      files = extract_applicable_files(options)
      linters = extract_enabled_linters(config, options)

      raise HamlLint::Exceptions::NoLintersError, 'No linters specified' if linters.empty?

      @lints = []
      files.each do |file|
        find_lints(file, linters)
      end

      linters.each do |linter|
        @lints += linter.lints
      end

      HamlLint::Report.new(@lints)
    end

  private

    def load_applicable_config(options)
      if options[:config_file]
        HamlLint::ConfigurationLoader.load_file(options[:config_file])
      else
        HamlLint::ConfigurationLoader.load_applicable_config
      end
    end

    def extract_enabled_linters(config, options)
      included_linters = LinterRegistry
        .extract_linters_from(options.fetch(:included_linters, []))

      included_linters = LinterRegistry.linters if included_linters.empty?

      excluded_linters = LinterRegistry
        .extract_linters_from(options.fetch(:excluded_linters, []))

      # After filtering out explicitly included/excluded linters, only include
      # linters which are enabled in the configuration
      (included_linters - excluded_linters).map(&:new).select do |linter|
        config.linter_enabled?(linter)
      end
    end

    def find_lints(file, linters)
      parser = Parser.new(file)

      linters.each do |linter|
        linter.run(parser)
      end
    rescue Haml::Error => ex
      @lints << Lint.new(file, ex.line, ex.to_s, :error)
    end

    def extract_applicable_files(options)
      excluded_files = options.fetch(:excluded_files, [])

      Utils.extract_files_from(options[:files]).reject do |file|
        excluded_files.any? do |exclusion_glob|
          File.fnmatch?(exclusion_glob, file)
        end
      end
    end
  end
end
