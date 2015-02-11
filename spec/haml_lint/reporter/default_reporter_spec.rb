require 'spec_helper'

describe HamlLint::Reporter::DefaultReporter do
  subject { HamlLint::Reporter::DefaultReporter.new(lints) }

  describe '#report_lints' do
    let(:io) { StringIO.new }
    let(:output) { io.string }
    let(:logger) { HamlLint::Logger.new(io) }
    let(:report) { HamlLint::Report.new(lints, []) }
    let(:reporter) { described_class.new(logger, report) }

    subject { reporter.report_lints }

    context 'when there are no lints' do
      let(:lints) { [] }

      it 'prints nothing' do
        subject
        output.should be_empty
      end
    end

    context 'when there are lints' do
      let(:filenames)    { ['some-filename.haml', 'other-filename.haml'] }
      let(:lines)        { [502, 724] }
      let(:descriptions) { ['Description of lint 1', 'Description of lint 2'] }
      let(:severities)   { [:warning] * 2 }

      let(:lints) do
        filenames.each_with_index.map do |filename, index|
          HamlLint::Lint.new(nil, filename, lines[index], descriptions[index], severities[index])
        end
      end

      it 'prints each lint on its own line' do
        subject
        output.count("\n").should == 2
      end

      it 'prints a trailing newline' do
        subject
        output[-1].should == "\n"
      end

      it 'prints the filename for each lint' do
        subject
        filenames.each do |filename|
          output.scan(/#{filename}/).count.should == 1
        end
      end

      it 'prints the line number for each lint' do
        subject
        lines.each do |line|
          output.scan(/#{line}/).count.should == 1
        end
      end

      it 'prints the description for each lint' do
        subject
        descriptions.each do |description|
          output.scan(/#{description}/).count.should == 1
        end
      end

      context 'when lints are warnings' do
        it 'prints the warning severity code on each line' do
          subject
          output.split("\n").each do |line|
            line.scan(/\[W\]/).count.should == 1
          end
        end
      end

      context 'when lints are errors' do
        let(:severities) { [:error] * 2 }

        it 'prints the error severity code on each line' do
          subject
          output.split("\n").each do |line|
            line.scan(/\[E\]/).count.should == 1
          end
        end
      end
    end
  end
end
