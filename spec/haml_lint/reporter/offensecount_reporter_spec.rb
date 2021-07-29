# frozen_string_literal: true

RSpec.describe HamlLint::Reporter::OffensecountReporter do
  let(:files) { ['some-filename.haml'] }
  let(:io) { StringIO.new }
  let(:output) { io.string }
  let(:logger) { HamlLint::Logger.new(io) }
  let(:report) { HamlLint::Report.new(lints: lints, files: files, reporter: reporter) }
  let(:reporter) { described_class.new(logger) }

  describe '#display_report' do
    subject { reporter.display_report(report) }

    context 'when there are no lints' do
      let(:lints) { [] }

      it 'prints nothing' do
        subject
        output.should == ''
      end
    end

    context 'when there are lints' do
      let(:linter) { [double(name: 'SomeLinter'), double(name: 'DifferentLinter'), double(name: 'SomeLinter')] }
      let(:filenames) { %w[some-filename.haml other-filename.haml thirdfilename.haml] }
      let(:lines) { %w[502 724 222] }
      let(:descriptions) { ['Description of lint 1', 'Description of "lint" 2', 'Description 3'] }
      let(:severities) { %i[warning error warning] }

      let(:lints) do
        filenames.each_with_index.map do |filename, index|
          HamlLint::Lint.new(linter[index],
                             filename,
                             lines[index],
                             descriptions[index],
                             severities[index])
        end
      end

      it 'prints the name of each linter' do
        subject
        output.should match linter[0].name
        output.should match linter[1].name
      end

      it 'prints a line for each linter' do
        subject
        output.split('--')[0].count("\n").should == 2
      end

      it 'prints the count of how many of each lint were found in descending order' do
        subject
        first_line, second_line = output.split("\n")
        first_line.should start_with('2 ')
        second_line.should start_with('1 ')
      end

      context 'when the linter is RuboCop' do
        let(:linter) { [double(name: 'RuboCop', message: descriptions[0])] }
        let(:filenames) { %w[some-filename.haml] }
        let(:lines) { %w[502] }
        let(:descriptions) { ['Offense: Description of lint'] }
        let(:severities) { %i[warning] }

        let(:lints) do
          filenames.each_with_index.map do |filename, index|
            HamlLint::Lint.new(linter[index],
                               filename,
                               lines[index],
                               descriptions[index],
                               severities[index])
          end
        end
        it 'prints the name of each linter' do
          subject
          output.should match 'RuboCop: Offense'
        end
      end
    end
  end
end
