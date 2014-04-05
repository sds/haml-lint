require 'spec_helper'
require 'haml_lint/cli'

describe HamlLint::CLI do
  let(:io) { StringIO.new }
  let(:output) { io.string }
  let(:logger) { HamlLint::Logger.new(io) }
  let(:cli) { described_class.new(logger) }

  describe '#run' do
    subject { cli.run(args) }
    let(:args) { [] }
    let(:options) { HamlLint::Options.new }

    it 'passes the arguments to the Options#parse method' do
      HamlLint::Options.any_instance.should_receive(:parse).with(args)
      subject
    end

    context 'when no arguments are given' do
      before { HamlLint::Runner.any_instance.stub(:run) }

      it 'scans for lints' do
        HamlLint::Runner.any_instance.should_receive(:run)
        subject
      end
    end

    context 'when arguments are given' do
      let(:args) { %w[file.haml some-view-*.haml] }

      before { HamlLint::Runner.any_instance.stub(:run) }

      it 'scans for lints' do
        HamlLint::Runner.any_instance.should_receive(:run)
        subject
      end
    end

    context 'when passed the --show-linters flag' do
      let(:args) { ['--show-linters'] }

      let(:fake_linter) do
        linter = double('linter')
        linter.stub(:name).and_return('FakeLinter')
        linter
      end

      before do
        HamlLint::LinterRegistry.stub(:linters).and_return([fake_linter])
      end

      it 'displays the available linters' do
        subject
        output.should include 'FakeLinter'
      end

      it { should == Sysexits::EX_OK }
    end

    context 'when passed the --version flag' do
      let(:args) { ['--version'] }

      it 'displays the application name' do
        subject
        output.should include HamlLint::APP_NAME
      end

      it 'displays the version' do
        subject
        output.should include HamlLint::VERSION
      end
    end

    context 'when invalid argument is given' do
      let(:args) { ['--some-invalid-argument'] }

      it 'displays message about invalid option' do
        subject
        output.should =~ /invalid option/i
      end

      it { should == Sysexits::EX_USAGE }
    end

    context 'when an unhandled exception occurs' do
      let(:backtrace) { %w[file1.rb:1 file2.rb:2] }
      let(:error_msg) { 'Oops' }

      let(:exception) do
        StandardError.new(error_msg).tap { |e| e.set_backtrace(backtrace) }
      end

      before { cli.stub(:act_on_options).and_raise(exception) }

      it 'displays error message' do
        subject
        output.should include error_msg
      end

      it 'displays backtrace' do
        subject
        output.should include backtrace.join("\n")
      end

      it 'displays link to bug report URL' do
        subject
        output.should include HamlLint::BUG_REPORT_URL
      end

      it { should == Sysexits::EX_SOFTWARE }
    end
  end

  describe '#report_lints' do
    context 'when the same file has 2 errors but only one line' do
      let(:filenames)    { ['some-filename.haml', 'some-filename.haml'] }
      let(:lines)        { [502, nil] }
      let(:descriptions) { ['Description of lint 1', 'Description of lint 2'] }
      let(:severities)   { [:warning] * 2 }

      let(:lints) do
        filenames.each_with_index.map do |filename, index|
          HamlLint::Lint.new(filename, lines[index], descriptions[index],
                             severities[index])
        end
      end

      subject { HamlLint::CLI.new }

      it 'sorts without raising error' do
        expect { subject.send(:report_lints, lints) }.to_not raise_error
      end
    end
  end
end
