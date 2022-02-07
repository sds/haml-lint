# frozen_string_literal: true

require 'haml_lint/options'

describe HamlLint::Options do
  describe '#parse' do
    subject { super().parse(args) }
    let(:args) { [] }

    context 'with a configuration file specified' do
      let(:args) { %w[--config some-config.yml] }

      it 'sets the `config_file` option to that file path' do
        subject.should include config_file: 'some-config.yml'
      end
    end

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

    context 'with a reporter option' do
      context 'for a reporter that exists' do
        let(:args) { %w[--reporter Json] }

        it 'sets the `reporter` option' do
          subject.should include reporter: HamlLint::Reporter::JsonReporter
        end
      end

      context 'for a reporter that exists when capitalized' do
        let(:args) { %w[--reporter json] }

        it 'sets the `reporter` option' do
          subject.should include reporter: HamlLint::Reporter::JsonReporter
        end
      end

      context 'for a reporter that does not exist' do
        let(:args) { %w[--reporter NonExistent] }

        it 'raises an error' do
          expect { subject }.to raise_error HamlLint::Exceptions::InvalidCLIOption
        end
      end
    end

    context 'with a fail level option' do
      let(:args) { %w[--fail-level error] }

      it 'sets the `fail_level` option' do
        subject[:fail_level].should == :error
      end

      context 'for an unknown fail level' do
        let(:args) { %w[--fail-level wazoo] }

        it 'raise an error' do
          expect { subject }.to raise_error HamlLint::Exceptions::UnknownSeverity
        end
      end
    end

    context 'with a parallel option' do
      let(:args) { %w[--parallel] }

      it 'sets the parallel option' do
        subject[:parallel].should == true
      end
    end

    context 'with an auto-correct option' do
      let(:args) { %w[--auto-correct] }

      it 'sets the autocorrect option to safe' do
        subject[:autocorrect].should == :safe
      end
    end

    context 'with a -a option' do
      let(:args) { %w[-a] }

      it 'sets the autocorrect option to safe' do
        subject[:autocorrect].should == :safe
      end
    end

    context 'with an auto-correct-all option' do
      let(:args) { %w[--auto-correct-all] }

      it 'sets the autocorrect option to all' do
        subject[:autocorrect].should == :all
      end
    end

    context 'with a -A option' do
      let(:args) { %w[--auto-correct-all] }

      it 'sets the autocorrect option to all' do
        subject[:autocorrect].should == :all
      end
    end

    context 'with a --auto-correct-only' do
      let(:args) { %w[--auto-correct-only] }

      it 'sets the autocorrect option to safe' do
        subject[:autocorrect].should == :safe
      end

      it 'sets the autocorrect_only option to true' do
        subject[:autocorrect_only].should == true
      end
    end

    context 'with a --auto-correct-all --auto-correct-only' do
      let(:args) { %w[--auto-correct-all --auto-correct-only] }

      it 'sets the autocorrect option to safe' do
        subject[:autocorrect].should == :all
      end

      it 'sets the autocorrect_only option to true' do
        subject[:autocorrect_only].should == true
      end
    end

    context 'with a --auto-correct-only --auto-correct-all' do
      let(:args) { %w[--auto-correct-only --auto-correct-all] }

      it 'sets the autocorrect option to safe' do
        subject[:autocorrect].should == :all
      end

      it 'sets the autocorrect_only option to true' do
        subject[:autocorrect_only].should == true
      end
    end

    context 'fail fast' do
      let(:args) { %w[--fail-fast] }

      it 'sets the fail_fast option' do
        subject[:fail_fast].should == true
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

    context 'with the verbose version option' do
      let(:args) { ['--verbose-version'] }

      it 'sets the `verbose_version` option' do
        subject.should include verbose_version: true
      end
    end

    context 'color' do
      describe 'manually on' do
        let(:args) { ['--color'] }

        it 'sets the `color` option to true' do
          subject.should include color: true
        end
      end

      describe 'manually off' do
        let(:args) { ['--no-color'] }

        it 'sets the `color option to false' do
          subject.should include color: false
        end
      end
    end

    context 'summary' do
      describe 'manually on' do
        let(:args) { ['--summary'] }

        it 'sets the `summary` option to true' do
          subject.should include summary: true
        end
      end

      describe 'manually off' do
        let(:args) { ['--no-summary'] }

        it 'sets the `summary option to false' do
          subject.should include summary: false
        end
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
