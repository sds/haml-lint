require 'spec_helper'

RSpec.describe HamlLint::Report do
  let(:fail_level) { :warning }
  let(:filenames) { ['some-filename.haml'] }
  let(:lints) { [] }
  let(:logger) { HamlLint::Logger.new(StringIO.new) }
  let(:reporter) { HamlLint::Reporter::DefaultReporter.new(logger) }

  subject(:report) do
    described_class.new(lints: lints, files: filenames,
                        fail_level: fail_level, reporter: reporter)
  end

  describe '#failed?' do
    subject { report.failed? }

    context 'with no lints' do
      describe '#failed?' do
        subject { report.failed? }

        it { should == false }
      end
    end

    context 'with only warning lints' do
      let(:lines)        { [502] }
      let(:descriptions) { ['Description of lint 1'] }
      let(:severities)   { [:warning] * 2 }
      let(:linter)       { double(name: 'SomeLinter') }

      let(:lints) do
        lines.each_with_index.map do |line, index|
          HamlLint::Lint.new(linter, filenames[index], line, descriptions[index], severities[index])
        end
      end

      context 'when fail level is :error' do
        let(:fail_level) { :error }

        it { should == false }
      end

      context 'when fail level is :warning' do
        let(:fail_level) { :warning }

        it { should == true }
      end
    end

    context 'with only error lints' do
      let(:lines)        { [502] }
      let(:descriptions) { ['Description of lint 1'] }
      let(:severities)   { [:error] * 2 }
      let(:linter)       { double(name: 'SomeLinter') }

      let(:lints) do
        lines.each_with_index.map do |line, index|
          HamlLint::Lint.new(linter, filenames[index], line, descriptions[index], severities[index])
        end
      end

      context 'when fail level is :error' do
        let(:fail_level) { :error }

        it { should == true }
      end

      context 'when fail level is :warning' do
        let(:fail_level) { :warning }

        it { should == true }
      end
    end
  end
end
