# frozen_string_literal: true

require 'rubocop'
require 'tempfile'

module HamlLint
  # Runs RuboCop on the Ruby code contained within HAML templates.
  #
  # The processing is done by extracting a Ruby file that matches the content, including
  # the indentation, of the HAML file. This way, we can run RuboCop with autocorrect
  # and get new Ruby code which should be HAML compatible.
  #
  # The ruby extraction makes "Chunks" which wrap each HAML constructs. The Chunks can then
  # use the corrected Ruby code to apply the corrections back in the HAML using logic specific
  # to each type of Chunk.
  #
  # The work is spread across the classes in the HamlLint::RubyExtraction module.
  class Linter::RuboCop < Linter
    # Processes a ruby file and reports RuboCop offenses
    class Runner < ::RuboCop::Runner
      attr_reader :offenses

      def run(haml_path, ruby_code, config:, allow_cache: false)
        @allow_cache = allow_cache
        @offenses = []
        @config_store.instance_variable_set(:@options_config, config)
        @options[:stdin] = ruby_code
        super([haml_path])
      end

      def corrected_code
        @options[:stdin]
      end

      # Executed when a file has been scanned by RuboCop, adding the reported
      # offenses to our collection.
      #
      # @param _file [String]
      # @param offenses [Array<RuboCop::Cop::Offense>]
      def file_finished(_file, offenses)
        @offenses = offenses
      end

      # RuboCop caches results by taking a hash of the file contents & path, among other things.
      # It disables its cache when working on file-content from stdin.
      # Unfortunately we always use RuboCop's stdin, even when we're linting a file on-disk.
      # So, override RuboCop::Runner#cached_run? so that it'll allow caching results, so long
      # as haml-lint itself isn't being invoked with files on stdin.
      def cached_run?
        return false unless @allow_cache

        @cached_run ||=
          (@options[:cache] == 'true' ||
          (@options[:cache] != 'false' && @config_store.for_pwd.for_all_cops['UseCache'])) &&
          !@options[:auto_gen_config]
      end
    end

    include LinterRegistry

    supports_autocorrect(true)

    # Maps the ::RuboCop::Cop::Severity levels to our own levels.
    SEVERITY_MAP = {
      error: :error,
      fatal: :error,
      convention: :warning,
      refactor: :warning,
      warning: :warning,
      info: :info,
    }.freeze

    # Debug fields, also used in tests
    attr_accessor :last_extracted_source
    attr_accessor :last_new_ruby_source

    def visit_root(_node) # rubocop:disable Metrics
      # Need to call the received block to avoid Linter automatically visiting children
      # Only important thing is that the argument is not ":children"
      yield :skip_children

      if document.indentation && document.indentation != '  '
        @lints <<
          HamlLint::Lint.new(
            self,
            document.file,
            nil,
            "Only supported indentation is 2 spaces, got: #{document.indentation.dump}",
            :error
          )
        return
      end

      @last_extracted_source = nil
      @last_new_ruby_source = nil

      coordinator = HamlLint::RubyExtraction::Coordinator.new(document)

      extracted_source = coordinator.extract_ruby_source
      if ENV['HAML_LINT_INTERNAL_DEBUG'] == 'true'
        puts "------ Extracted ruby from #{@document.file}:"
        puts extracted_source.source
        puts '------'
      end

      @last_extracted_source = extracted_source

      if extracted_source.source.empty?
        @last_new_ruby_source = ''
        return
      end

      new_ruby_code = process_ruby_source(extracted_source.source, extracted_source.source_map)

      if @autocorrect && ENV['HAML_LINT_INTERNAL_DEBUG'] == 'true'
        puts "------ Autocorrected extracted ruby from #{@document.file}:"
        puts new_ruby_code
        puts '------'
      end

      if @autocorrect && transfer_corrections?(extracted_source.source, new_ruby_code)
        @last_new_ruby_source = new_ruby_code
        transfer_corrections(coordinator, new_ruby_code)
      end
    end

    def self.cops_names_not_supporting_autocorrect
      return @cops_names_not_supporting_autocorrect if @cops_names_not_supporting_autocorrect
      return [] unless ::RuboCop::Cop::Registry.respond_to?(:all)

      cops_without_autocorrect = ::RuboCop::Cop::Registry.all.reject(&:support_autocorrect?)
      # This cop cannot be disabled
      cops_without_autocorrect.delete(::RuboCop::Cop::Lint::Syntax)
      @cops_names_not_supporting_autocorrect = cops_without_autocorrect.map { |cop| cop.badge.to_s }.freeze
    end

    private

    def rubocop_config_for(path)
      user_config_path = ENV['HAML_LINT_RUBOCOP_CONF'] || config['config_file']
      user_config_path ||= rubocop_config_store.user_rubocop_config_path_for(path)
      user_config_path = File.absolute_path(user_config_path)
      rubocop_config_store.config_object_pointing_to(user_config_path)
    end

    # Extracted here so that tests can stub this to always return true
    def transfer_corrections?(initial_ruby_code, new_ruby_code)
      initial_ruby_code != new_ruby_code
    end

    def transfer_corrections(coordinator, new_ruby_code)
      begin
        new_haml_lines = coordinator.haml_lines_with_corrections_applied(new_ruby_code)
      rescue HamlLint::RubyExtraction::UnableToTransferCorrections => e
        # Those are lints we couldn't correct. If haml-lint was called without the
        # --auto-correct-only, then this linter will be called again without autocorrect,
        # so the lints will be recorded then.
        @lints = []

        msg = "Corrections couldn't be transferred: #{e.message} - Consider linting the file " \
              'without auto-correct and doing the changes manually.'
        if ENV['HAML_LINT_DEBUG'] == 'true'
          msg = "#{msg} DEBUG: Rubocop corrected Ruby code follows:\n#{new_ruby_code}\n------"
        end

        @lints << HamlLint::Lint.new(self, document.file, nil, msg, :error)
        return
      end

      new_haml_string = new_haml_lines.join("\n")

      if new_haml_validity_checks(new_haml_string)
        document.change_source(new_haml_string)
        true
      else
        false
      end
    end

    def new_haml_validity_checks(new_haml_string)
      new_haml_error = HamlLint::Utils.check_error_when_compiling_haml(new_haml_string)
      return true unless new_haml_error

      error_message = if new_haml_error.is_a?(::SyntaxError)
                        'Corrections by haml-lint generate Haml that will have Ruby syntax error. Skipping.'
                      else
                        'Corrections by haml-lint generate invalid Haml. Skipping.'
                      end

      if ENV['HAML_LINT_DEBUG'] == 'true'
        error_message = error_message.dup
        error_message << "\nDEBUG: Here is the exception:\n#{new_haml_error.full_message}"

        error_message << "DEBUG: This is the (wrong) HAML after the corrections:\n"
        if new_haml_error.respond_to?(:line)
          error_message << "(DEBUG: Line number of error in the HAML: #{new_haml_error.line})\n"
        end
        error_message << new_haml_string
      else
        # Those are lints we couldn't correct. If haml-lint was called without the
        # --auto-correct-only, then this linter will be called again without autocorrect,
        # so the lints will be recorded then. If it was called with --auto-correct-only,
        # then we did nothing so it makes sense not to show the lints.
        @lints = []
      end

      @lints << HamlLint::Lint.new(self, document.file, nil, error_message, :error)
      false
    end

    # A single RuboCop runner is shared between files to avoid RuboCop
    # having to repeatedly reload .rubocop.yml.
    def rubocop_runner
      @rubocop_runner ||= Runner.new(rubocop_options, ::RuboCop::ConfigStore.new)
    end

    def rubocop_config_store
      @rubocop_config_store ||= RubocopConfigStore.new
    end

    # Executes RuboCop against the given Ruby code, records the offenses as
    # lints, runs autocorrect if requested and returns the corrected ruby.
    #
    # @param ruby_code [String] Ruby code
    # @param source_map [Hash] map of Ruby code line numbers to original line
    #   numbers in the template
    # @return [String] The autocorrected Ruby source code
    def process_ruby_source(ruby_code, source_map)
      filename = document.file || 'ruby_script.rb'

      offenses, corrected_ruby = run_rubocop(rubocop_runner, ruby_code, filename)

      extract_lints_from_offenses(offenses, source_map)
      corrected_ruby
    end

    # Runs RuboCop, returning the offenses and corrected code. Raises when RuboCop
    # fails to run correctly.
    #
    # @param rubocop_runner [HamlLint::Linter::RuboCop::Runner] There to simplify tests by using a stub
    # @param ruby_code [String] The ruby code to run through RuboCop
    # @param path [String] the path to tell RuboCop we are running
    # @return [Array<RuboCop::Cop::Offense>, String]
    def run_rubocop(rubocop_runner, ruby_code, path) # rubocop:disable Metrics
      rubocop_runner.run(path, ruby_code, config: rubocop_config_for(path), allow_cache: @document&.file_on_disk)

      if ENV['HAML_LINT_INTERNAL_DEBUG'] == 'true'
        if rubocop_runner.offenses.empty?
          puts "------ No lints found by RuboCop in #{@document.file}"
        else
          puts "------ Raw lints found by RuboCop in #{@document.file}"
          rubocop_runner.offenses.each do |offense|
            puts offense
          end
          puts '------'
        end
      end

      if @autocorrect
        corrected_ruby = rubocop_runner.corrected_code
      end

      [rubocop_runner.offenses, corrected_ruby]
    rescue ::RuboCop::Error => e
      raise HamlLint::Exceptions::ConfigurationError,
            "RuboCop raised #{e}." \
            ' Here is its output to check the stack trace or see if there was' \
            " a misconfiguration:\n#{e.message}\n#{e.backtrace}"
    end

    # Aggregates RuboCop offenses and converts them to {HamlLint::Lint}s
    # suitable for reporting.
    #
    # @param offenses [Array<RuboCop::Cop::Offense>]
    # @param source_map [Hash]
    def extract_lints_from_offenses(offenses, source_map) # rubocop:disable Metrics
      offenses.each do |offense|
        next if Array(config['ignored_cops']).include?(offense.cop_name)
        autocorrected = offense.status == :corrected

        # There will be another execution to deal with not auto-corrected stuff unless
        # we are in autocorrect-only mode, where we don't want not auto-corrected stuff.
        next if @autocorrect && !autocorrected && offense.cop_name != 'Lint/Syntax'

        if ENV['HAML_LINT_INTERNAL_DEBUG']
          line = offense.line
        else
          line = source_map[offense.line]

          if line.nil? && offense.line == source_map.keys.max + 1
            # The sourcemap doesn't include an entry for the line just after the last line,
            # but rubocop sometimes does place offenses there.
            line = source_map[offense.line - 1]
          end
        end
        record_lint(line, offense.message, offense.severity.name,
                    corrected: autocorrected)
      end
    end

    # Record a lint for reporting back to the user.
    #
    # @param line [#line] line number of the lint
    # @param message [String] error/warning to display to the user
    # @param severity [Symbol] RuboCop severity level for the offense
    def record_lint(line, message, severity, corrected:)
      # TODO: actual handling for RuboCop's new :info severity
      return if severity == :info

      @lints << HamlLint::Lint.new(self, @document.file, line, message,
                                   SEVERITY_MAP.fetch(severity, :warning),
                                   corrected: corrected)
    end

    # rubocop:disable Style/MutableConstant
    # Using BaseFormatter suppresses any default output
    DEFAULT_FLAGS = %w[--format RuboCop::Formatter::BaseFormatter]
    begin
      ::RuboCop::Options.new.parse(['--raise-cop-error'])
      DEFAULT_FLAGS << '--raise-cop-error'
    rescue OptionParser::InvalidOption
      # older versions of RuboCop don't support this flag
    end
    DEFAULT_FLAGS.freeze
    # rubocop:enable Style/MutableConstant

    # Returns options that will be passed to the RuboCop runner.
    #
    # @return [Hash]
    def rubocop_options
      flags = DEFAULT_FLAGS
      flags += ignored_cops_flags
      flags += rubocop_autocorrect_flags
      options, _args = ::RuboCop::Options.new.parse(flags)
      options
    end

    def rubocop_autocorrect_flags
      return [] unless @autocorrect

      rubocop_version = Gem::Version.new(::RuboCop::Version::STRING)

      case @autocorrect
      when :safe
        if rubocop_version >= Gem::Version.new('1.30')
          ['--autocorrect']
        else
          ['--auto-correct']
        end
      when :all
        if rubocop_version >= Gem::Version.new('1.30')
          ['--autocorrect-all']
        else
          ['--auto-correct-all']
        end
      else
        raise "Unexpected autocorrect option: #{@autocorrect.inspect}"
      end
    end

    # Because of autocorrect, we need to pass the ignored cops to RuboCop to
    # prevent it from doing fixes we don't want.
    # Because cop names changed names over time, we cleanup those that don't exist
    # anymore or don't exist yet.
    # This is not exhaustive, it's only for the cops that are in config/default.yml
    def ignored_cops_flags
      ignored_cops = config.fetch('ignored_cops', [])

      if @autocorrect
        ignored_cops += self.class.cops_names_not_supporting_autocorrect
      end

      return [] if ignored_cops.empty?
      ['--except', ignored_cops.uniq.join(',')]
    end

    # Exclude ivars that don't marshal properly
    def marshal_dump
      excluded_ivars = %i[@rubocop_runner @rubocop_config_store @user_config_path_to_config_object]
      (instance_variables - excluded_ivars).to_h do |ivar|
        [ivar, instance_variable_get(ivar)]
      end
    end

    def marshal_load(ivars)
      ivars.each do |k, v|
        instance_variable_set(k, v)
      end
    end
  end

  # To handle our need to force some configurations on RuboCop, while still allowing users
  # to customize most of RuboCop using their own rubocop.yml config(s), we need to detect
  # the effective RuboCop configuration for a specific file, and generate a new configuration
  # containing our own "forced configuration" with a `inherit_from` that points on the
  # user's configuration.
  #
  # This class handles all of this logic.
  class RubocopConfigStore
    def initialize
      @dir_path_to_user_config_path = {}
      @user_config_path_to_config_object = {}
    end

    # Build a RuboCop::Config from config/forced_rubocop_config.yml which inherits from the given
    # user_config_path and return it's path.
    def config_object_pointing_to(user_config_path)
      if @user_config_path_to_config_object[user_config_path]
        return @user_config_path_to_config_object[user_config_path]
      end

      final_config_hash = forced_rubocop_config_hash.dup

      if user_config_path != ::RuboCop::ConfigLoader::DEFAULT_FILE
        # If we manually inherit from the default RuboCop config, we may get warnings
        # for deprecated stuff that is in it. We don't when we automatically
        # inherit from it (which always happens)
        final_config_hash['inherit_from'] = user_config_path
      end

      config_object = Tempfile.create(['.haml-lint-rubocop', '.yml']) do |tempfile|
        tempfile.write(final_config_hash.to_yaml)
        tempfile.close
        ::RuboCop::ConfigLoader.configuration_from_file(tempfile.path)
      end

      @user_config_path_to_config_object[user_config_path] = config_object
    end

    # Find the path to the effective RuboCop configuration for a path (file or dir)
    def user_rubocop_config_path_for(path)
      dir = if File.directory?(path)
              path
            else
              File.dirname(path)
            end

      @dir_path_to_user_config_path[dir] ||= ::RuboCop::ConfigLoader.configuration_file_for(dir)
    end

    # Returns the content (Hash) of config/forced_rubocop_config.yml after processing it's ERB content.
    # Cached since it doesn't change between files
    def forced_rubocop_config_hash
      return @forced_rubocop_config_hash if @forced_rubocop_config_hash

      content = File.read(File.join(HamlLint::HOME, 'config', 'forced_rubocop_config.yml'))
      processed_content = HamlLint::Utils.process_erb(content)
      hash = YAML.safe_load(processed_content)

      if ENV['HAML_LINT_TESTING']
        # In newer RuboCop versions, new cops are not enabled by default, and instead
        # show a message until they are used. We just want a default for them
        # to avoid spamming STDOUT. Making it "disable" reduces the chances of having
        # the test suite start failing after a new cop gets added.
        hash['AllCops'] ||= {}
        if Gem::Version.new(::RuboCop::Version::STRING) >= Gem::Version.new('1')
          hash['AllCops']['NewCops'] = 'disable'
        end
      end

      @forced_rubocop_config_hash = hash.freeze
    end
  end
end
