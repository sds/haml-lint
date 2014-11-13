require 'rake'
require 'rake/tasklib'

module HamlLint
  # Rake task interface
  class RakeTask < Rake::TaskLib
    attr_accessor :name
    attr_accessor :include_linter
    attr_accessor :exclude_linter
    attr_accessor :config
    attr_accessor :exclude
    attr_accessor :pattern

    def initialize(*args, &task_block)
      init_args(args)

      desc 'Run haml-lint' unless ::Rake.application.last_comment

      task(name, *args) do |_, task_args|
        task_block &&
          task_block.call(*[self, task_args].first(task_block.arity))

        run_cli
      end
    end

    private

    def init_args(args)
      @name = args.shift || 'haml_lint'
      @include_linter = []
      @exclude_linter = []
      @config = ''
      @exclude = []
      @pattern = %w[./**/*.haml]
    end

    def cli_args
      args = %w[@include_linter @exclude_linter @config @exclude].map do |ivar|
        content = instance_variable_get(ivar)
        next if content.empty?

        arg = ivar.tr('_', '-').delete('@')

        if content.is_a?(String)
          %W[--#{arg} #{content}]
        elsif content.is_a?(Array)
          %W[--#{arg} #{content.join(',')}]
        else
          fail ArgumentError, "Unexpected type for #{ivar}"
        end
      end

      (args << @pattern).flatten.compact
    end

    def run_cli
      require 'haml_lint'
      require 'haml_lint/cli'

      logger = HamlLint::Logger.new(STDOUT)
      result = HamlLint::CLI.new(logger).run(cli_args)
      abort('HamlLint failed') unless result == 0
    end
  end
end
