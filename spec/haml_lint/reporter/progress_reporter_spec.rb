require 'spec_helper'

RSpec.describe HamlLint::Reporter::ProgressReporter do
  let(:files)    { ['some-filename.haml'] }
  let(:io)       { StringIO.new }
  let(:output)   { io.string }
  let(:logger)   { HamlLint::Logger.new(io) }
  let(:report)   { HamlLint::Report.new(lints: lints, files: files, reporter: reporter) }
  let(:reporter) { described_class.new(logger) }

  describe '#finished_file' do
    subject { files.each { |file| reporter.finished_file(file, lints) } }

    context 'when there are no lints' do
      let(:files) { ['some-filename.haml', 'other-filename.haml'] }
      let(:lints) { [] }

      it 'prints a dot for every file' do
        subject
        output.should eq('..')
      end
    end

    context 'when there are lints' do
      let(:descriptions) { ['Description of lint 1'] }
      let(:lines)        { [502] }
      let(:linter)       { double(name: 'SomeLinter') }

      let(:lints) do
        files.flat_map do |filename|
          descriptions.each_with_index.map do |descriptions, index|
            HamlLint::Lint.new(linter, filename, lines[index], descriptions, severities[index])
          end
        end
      end

      context 'when a warning severity offense is detected' do
        let(:severities) { %i[warning] }

        it 'prints a W' do
          subject
          output.should == 'W'
        end
      end

      context 'when an error severity code is detected' do
        let(:severities) { %i[error] }

        it 'prints an E' do
          subject
          output.should == 'E'
        end
      end

      context 'when different severity levels are detected' do
        let(:descriptions) { ['Description of lint 1', 'Description of lint 2'] }
        let(:lines)        { [502, 503] }
        let(:linter)       { double(name: 'SomeLinter') }
        let(:severities)   { %i[warning error] }

        it 'prints the mark for the worst lint' do
          subject
          output.should == 'E'
        end
      end
    end

    describe '#display_report' do
      subject { reporter.display_report(report) }

      context 'when there are no lints' do
        let(:files) { ['some-filename.haml', 'other-filename.haml'] }
        let(:lints) { [] }

        it 'prints the summary' do
          subject
          output.should == "\n2 files inspected, 0 lints detected\n"
        end
      end

      context 'when there are lints' do
        let(:files)        { ['some-filename.haml', 'other-filename.haml'] }
        let(:lines)        { [502, 724] }
        let(:descriptions) { ['Description of lint 1', 'Description of lint 2'] }
        let(:header)       { output.split("\n")[0..3].join("\n") }
        let(:linter)       { double(name: 'SomeLinter') }
        let(:offenses)     { output_without_summary.split("\n")[1..-1].join("\n") }
        let(:output_without_summary) { output.split("\n").reject(&:empty?)[0..-2].join("\n") }
        let(:severities)   { [:warning] * 2 }
        let(:summary)      { output.split("\n")[-2..-1].join("\n") }

        let(:lints) do
          files.each_with_index.map do |file, index|
            HamlLint::Lint.new(linter, file, lines[index], descriptions[index], severities[index])
          end
        end

        it 'prints the header' do
          subject
          header.should == "\n\nOffenses:\n"
        end

        it 'prints each lint on its own line' do
          subject
          offenses.split("\n").size.should == 2
        end

        it 'prints the summary' do
          subject
          summary.should == "\n2 files inspected, 2 lints detected"
        end
      end
    end

    describe '#start' do
      subject { reporter.start(files) }

      it 'states the number of files to inspect' do
        subject
        output.should == "Inspecting 1 file\n"
      end
    end
  end
end
