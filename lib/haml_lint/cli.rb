# frozen_string_literal: true

require_relative '../haml_lint'
require_relative 'options'

require 'sysexits'

module HamlLint
  # Command line application interface.
  class CLI
    # Create a CLI that outputs to the specified logger.
    #
    # @param logger [HamlLint::Logger, nil]
    def initialize(logger = nil)
      @log = logger
    end

    # Parses the given command-line arguments and executes appropriate logic
    # based on those arguments.
    #
    # @param args [Array<String>] command line arguments
    # @return [Integer] exit status code
    def run(args)
      options = HamlLint::Options.new.parse(args)
      act_on_options(options)
    rescue StandardError => e
      handle_exception(e)
    end

    private

    attr_reader :log

    # Given the provided options, execute the appropriate command.
    #
    # @return [Integer] exit status code
    def act_on_options(options) # rubocop:disable Metrics
      configure_logger(options)
      if options[:debug]
        ENV['HAML_LINT_DEBUG'] = 'true'
      end
      if options[:internal_debug]
        ENV['HAML_LINT_INTERNAL_DEBUG'] = 'true'
      end
      if options[:help]
        print_help(options)
        Sysexits::EX_OK
      elsif options[:version] || options[:verbose_version]
        print_version(options)
        Sysexits::EX_OK
      elsif options[:show_linters]
        print_available_linters
        Sysexits::EX_OK
      elsif options[:show_reporters]
        print_available_reporters
        Sysexits::EX_OK
      else
        scan_for_lints(options)
      end
    end

    # Given the provided options, configure the logger.
    #
    # @return [void]
    def configure_logger(options)
      @log ||= HamlLint::Logger.new(options[:stderr] ? $stderr : $stdout)
      log.color_enabled = options.fetch(:color, log.tty?)
      log.summary_enabled = options.fetch(:summary, true)
    end

    # Outputs a message and returns an appropriate error code for the specified
    # exception.
    def handle_exception(exception)
      case exception
      when HamlLint::Exceptions::ConfigurationError
        log.error exception.message
        Sysexits::EX_CONFIG
      when HamlLint::Exceptions::InvalidCLIOption
        log.error exception.message
        log.log "Run `#{APP_NAME}` --help for usage documentation"
        Sysexits::EX_USAGE
      when HamlLint::Exceptions::InvalidFilePath
        log.error exception.message
        Sysexits::EX_NOINPUT
      when HamlLint::Exceptions::NoLintersError
        log.error exception.message
        Sysexits::EX_NOINPUT
      else
        print_unexpected_exception(exception)
        Sysexits::EX_SOFTWARE
      end
    end

    # Instantiates a new reporter based on the options.
    #
    # @param options [HamlLint::Configuration]
    # @option options [true, nil] :auto_gen_config whether to use the config
    #   generating reporter
    # @option options [Class] :reporter the class of reporter to use
    # @return [HamlLint::Reporter]
    def reporter_from_options(options)
      if options[:auto_gen_config]
        HamlLint::Reporter::DisabledConfigReporter.new(log, limit: options[:auto_gen_exclude_limit] || 15)
      else
        options.fetch(:reporter, HamlLint::Reporter::DefaultReporter).new(log)
      end
    end

    # Scans the files specified by the given options for lints.
    #
    # @return [Integer] exit status code
    def scan_for_lints(options)
      reporter = reporter_from_options(options)
      report = Runner.new.run(options.merge(reporter: reporter))
      report.display
      report.failed? ? Sysexits::EX_DATAERR : Sysexits::EX_OK
    end

    # Outputs a list of all currently available linters.
    def print_available_linters
      log.info 'Available linters:'

      linter_names = HamlLint::LinterRegistry.linters.map do |linter|
        linter.name.split('::').last
      end

      linter_names.sort.each do |linter_name|
        log.log " - #{linter_name}"
      end
    end

    # Outputs a list of currently available reporters.
    def print_available_reporters
      log.info 'Available reporters:'

      HamlLint::Reporter.available.map(&:cli_name).sort.each do |reporter_name|
        log.log " - #{reporter_name}"
      end
    end

    # Outputs help documentation.
    def print_help(options)
      log.log options[:help]
    end

    # Outputs the application name and version.
    def print_version(options)
      log.log "#{HamlLint::APP_NAME} #{HamlLint::VERSION}"

      if options[:verbose_version]
        log.log "haml #{Gem.loaded_specs['haml'].version}"
        log.log "rubocop #{Gem.loaded_specs['rubocop'].version}"
        log.log RUBY_DESCRIPTION
      end
    end

    # Outputs the backtrace of an exception with instructions on how to report
    # the issue.
    def print_unexpected_exception(exception) # rubocop:disable Metrics/AbcSize
      log.bold_error exception.message
      log.error exception.backtrace.join("\n")
      log.warning 'Report this bug at ', false
      log.info HamlLint::BUG_REPORT_URL
      log.newline
      log.success 'To help fix this issue, please include:'
      log.log '- The above stack trace'
      log.log '- Haml-Lint version: ', false
      log.info HamlLint::VERSION
      log.log '- Haml version: ', false
      log.info Gem.loaded_specs['haml'].version
      log.log '- RuboCop version: ', false
      log.info Gem.loaded_specs['rubocop'].version
      log.log '- Ruby version: ', false
      log.info RUBY_VERSION
    end
  end
end
