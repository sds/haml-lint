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
      files = extract_applicable_files(options, config)
      linters = extract_enabled_linters(config, options)

      raise HamlLint::Exceptions::NoLintersError, 'No linters specified' if linters.empty?

      @lints = []
      files.each do |file|
        find_lints(file, linters, config)
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
      (included_linters - excluded_linters).map do |linter_class|
        linter_config = config.for_linter(linter_class)
        linter_class.new(linter_config) if linter_config['enabled']
      end.compact
    end

    def find_lints(file, linters, config)
      parser = Parser.new(file, config.hash)

      linters.each do |linter|
        linter.run(parser)
      end
    rescue Haml::Error => ex
      @lints << Lint.new(nil, file, ex.line, ex.to_s, :error)
    end

    def extract_applicable_files(options, config)
      included_patterns = options[:files]
      excluded_files = options.fetch(:excluded_files, [])

      HamlLint::FileFinder.new(config).find(included_patterns, excluded_files)
    end
  end
end
