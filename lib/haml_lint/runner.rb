module HamlLint
  # Responsible for running the applicable linters against the desired files.
  class Runner
    # Runs the appropriate linters against the desired files given the specified
    # options.
    #
    # @param [Hash] options
    # @option options :config_file [String] path of configuration file to load
    # @option options :config [HamlLint::Configuration] configuration to use
    # @option options :excluded_files [Array<String>]
    # @option options :included_linters [Array<String>]
    # @option options :excluded_linters [Array<String>]
    # @option options :fail_fast [true, false] flag for failing after first failure
    # @option options :fail_level
    # @option options :reporter [HamlLint::Reporter]
    # @return [HamlLint::Report] a summary of all lints found
    def run(options = {})
      @config = load_applicable_config(options)
      @files = extract_applicable_files(config, options)
      @linter_selector = HamlLint::LinterSelector.new(config, options)
      @fail_fast = options.fetch(:fail_fast, false)

      report(options)
    end

    private

    # The {HamlLint::Configuration} that should be used for this run.
    #
    # @return [HamlLint::Configuration]
    attr_reader :config

    # A flag for whether to fail after the first failure.
    #
    # @return [true, false]
    attr_reader :fail_fast

    # !@method fail_fast?
    #   Checks whether to fail after the first failure.
    #
    #   @return [true, false]
    alias fail_fast? fail_fast

    # The list of files to lint during this run.
    #
    # @return [Array<String>]
    attr_reader :files

    # The selector for which linters to run during this run.
    #
    # @return [HamlLint::LinterSelector]
    attr_reader :linter_selector

    # Returns the {HamlLint::Configuration} that should be used given the
    # specified options.
    #
    # @param options [Hash]
    # @return [HamlLint::Configuration]
    def load_applicable_config(options)
      if options[:config_file]
        HamlLint::ConfigurationLoader.load_file(options[:config_file])
      elsif options[:config]
        options[:config]
      else
        HamlLint::ConfigurationLoader.load_applicable_config
      end
    end

    # Runs all provided linters using the specified config against the given
    # file.
    #
    # @param file [String] path to file to lint
    # @param linter_selector [HamlLint::LinterSelector]
    # @param config [HamlLint::Configuration]
    def collect_lints(file, linter_selector, config)
      begin
        document = HamlLint::Document.new(File.read(file), file: file, config: config)
      rescue HamlLint::Exceptions::ParseError => ex
        return [HamlLint::Lint.new(HamlLint::Linter::Syntax.new(config), file,
                                   ex.line, ex.to_s, :error)]
      end

      linter_selector.linters_for_file(file).map do |linter|
        linter.run(document)
      end.flatten
    end

    # Returns the list of files that should be linted given the specified
    # configuration and options.
    #
    # @param config [HamlLint::Configuration]
    # @param options [Hash]
    # @return [Array<String>]
    def extract_applicable_files(config, options)
      included_patterns = options[:files]
      excluded_patterns = config['exclude']
      excluded_patterns += options.fetch(:excluded_files, [])

      HamlLint::FileFinder.new(config).find(included_patterns, excluded_patterns)
    end

    # Process the files and add them to the given report.
    #
    # @param report [HamlLint::Report]
    # @return [void]
    def process_files(report)
      files.each do |file|
        process_file(file, report)
        break if report.failed? && fail_fast?
      end
    end

    # Process a file and add it to the given report.
    #
    # @param file [String] the name of the file to process
    # @param report [HamlLint::Report]
    # @return [void]
    def process_file(file, report)
      lints = collect_lints(file, linter_selector, config)
      lints.each { |lint| report.add_lint(lint) }
      report.finish_file(file, lints)
    end

    # Generates a report based on the given options.
    #
    # @param options [Hash]
    # @option options :reporter [HamlLint::Reporter] the reporter to report with
    # @return [HamlLint::Report]
    def report(options)
      report = HamlLint::Report.new(reporter: options[:reporter])
      report.start(@files)
      process_files(report)
      report
    end
  end
end
