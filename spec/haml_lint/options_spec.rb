require 'spec_helper'

require 'haml_lint/options'

describe HamlLint::Options do
  describe '#parse' do
    subject { super().parse(args) }
    let(:args) { [] }

    context 'with a list of files to exclude' do
      let(:args) { %w[--exclude some-glob-pattern/*.haml,some-other-pattern.haml] }

      it 'sets the `excluded_files` option to that list of patterns' do
        subject.should include excluded_files: %w[some-glob-pattern/*.haml some-other-pattern.haml]
      end
    end

    context 'with a list of linters to include' do
      let(:args) { %w[--include-linter SomeLinter,SomeOtherLinter] }

      it 'sets the `included_linters` option to that list of linters' do
        subject.should include included_linters: %w[SomeLinter SomeOtherLinter]
      end
    end

    context 'with a list of linters to exclude' do
      let(:args) { %w[--exclude-linter SomeLinter,SomeOtherLinter] }

      it 'sets the `excluded_linters` option to that list of linters' do
        subject.should include excluded_linters: %w[SomeLinter SomeOtherLinter]
      end
    end

    context 'with the help option' do
      let(:args) { ['--help'] }

      it 'returns usage information in the `help` option' do
        subject[:help].should =~ /Usage/i
      end
    end

    context 'with the version option' do
      let(:args) { ['--version'] }

      it 'sets the `version` option' do
        subject.should include version: true
      end
    end

    context 'with a list of file glob patterns' do
      let(:args) { %w[app/**/*.haml some-dir/some-template.haml] }

      it 'sets the `files` option to that list of patterns' do
        subject.should include files: args
      end
    end

    context 'with an invalid argument' do
      let(:args) { ['--some-invalid-argument'] }

      it 'raises an invalid CLI option error' do
        expect { subject }.to raise_error HamlLint::Exceptions::InvalidCLIOption
      end
    end
  end
end
