require 'haml_lint/options'

require 'sysexits'

module HamlLint
  # Command line application interface.
  class CLI
    attr_accessor :options

    # @param logger [HamlLint::Logger]
    def initialize(logger)
      @log = logger
    end

    # Parses the given command-line arguments and executes appropriate logic
    # based on those arguments.
    #
    # @param args [Array<String>] command line arguments
    # @return [Fixnum] exit status returned by the application
    def run(args)
      options = HamlLint::Options.new.parse(args)

      act_on_options(options)
    rescue HamlLint::Exceptions::InvalidCLIOption => ex
      log.error ex.message
      log.log "Run `#{APP_NAME}` --help for usage documentation"
      Sysexits::EX_USAGE
    rescue => ex
      print_unexpected_exception(ex)
      Sysexits::EX_SOFTWARE
    end

  private

    attr_reader :log

    def act_on_options(options)
      if options[:help]
        print_help(options)
        SysExits::EX_OK
      elsif options[:version]
        print_version
        Sysexits::EX_OK
      elsif options[:show_linters]
        print_available_linters
        Sysexits::EX_OK
      else
        scan_for_lints(options)
      end
    end

    def scan_for_lints(options)
      report = Runner.new.run(options)
      print_report(report, options)
      report.failed? ? Sysexits::EX_DATAERR : Sysexits::EX_OK
    end

    def print_report(report, options)
      reporter = options.fetch(:reporter, Reporter::DefaultReporter).new(log, report)
      reporter.report_lints
    end

    def print_available_linters
      log.info 'Available linters:'

      linter_names = LinterRegistry.linters.map do |linter|
        linter.name.split('::').last
      end

      linter_names.sort.each do |linter_name|
        log.log " - #{linter_name}"
      end
    end

    def print_help(options)
      log.log options[:help]
    end

    def print_version
      log.log "#{APP_NAME} #{HamlLint::VERSION}"
    end

    def print_unexpected_exception(ex)
      log.bold_error ex.message
      log.error ex.backtrace.join("\n")
      log.warning 'Report this bug at ', false
      log.info HamlLint::BUG_REPORT_URL
    end
  end
end
