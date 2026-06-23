# frozen_string_literal: true

describe HamlLint::Reporter::GithubReporter do
  let(:filenames) { %w[some-filename.haml] }
  let(:io) { StringIO.new }
  let(:output) { io.string }
  let(:logger) { HamlLint::Logger.new(io) }
  let(:report) { HamlLint::Report.new(lints: lints, files: filenames, reporter: reporter, fail_level: :error) }
  let(:reporter) { described_class.new(logger) }

  describe '#added_lint' do
    subject { lints.each { |lint| reporter.added_lint(lint, report) } }

    context 'when there are no lints' do
      let(:lints) { [] }

      it 'prints nothing' do
        subject
        output.should == ''
      end
    end

    context 'when there are lints' do
      let(:filenames)    { ['some-filename.haml', 'other-filename.haml'] }
      let(:lines)        { [502, 724] }
      let(:descriptions) { ['Description of lint 1', 'Description of lint 2'] }
      let(:severities)   { [:warning] * 2 }
      let(:linter)       { double(name: 'SomeLinter') }

      let(:lints) do
        filenames.each_with_index.map do |filename, index|
          HamlLint::Lint.new(linter, filename, lines[index], descriptions[index], severities[index])
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

      it 'sets the workflow command file property for each lint' do
        subject
        filenames.each do |filename|
          output.scan(/file=#{filename}/).count.should == 1
        end
      end

      it 'sets the workflow command line property for each lint' do
        subject
        lines.each do |line|
          output.scan(/line=#{line}/).count.should == 1
        end
      end

      it 'sets the annotation title to the linter name for each lint' do
        subject
        output.scan(/title=haml-lint SomeLinter/).count.should == 2
      end

      it 'keeps the location and linter name in the message so the log stays readable' do
        subject
        filenames.each_with_index do |filename, index|
          location = "#{filename}:#{lines[index]} SomeLinter: #{descriptions[index]}"
          output.scan(/#{Regexp.escape(location)}/).count.should == 1
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
            line.scan(/::warning /).count.should == 1
          end
        end
      end

      context 'when lints are errors' do
        let(:severities) { [:error] * 2 }

        it 'prints the error severity code on each line' do
          subject
          output.split("\n").each do |line|
            line.scan(/::error /).count.should == 1
          end
        end
      end

      context 'when a message contains characters that delimit workflow commands' do
        let(:descriptions) { ["Use 100%% width\nand height", 'Description of lint 2'] }

        it 'escapes them so the command stays on a single line' do
          subject
          output.count("\n").should == 2
          output.should include('Use 100%25%25 width%0Aand height')
        end
      end

      context 'when lint has no associated linter' do
        let(:linter) { nil }

        it 'falls back to a generic annotation title' do
          subject
          output.scan(/title=haml-lint::/).count.should == 2
        end

        it 'keeps the location in the message without a linter name' do
          subject
          filenames.each_with_index do |filename, index|
            location = "#{filename}:#{lines[index]} #{descriptions[index]}"
            output.scan(/#{Regexp.escape(location)}/).count.should == 1
          end
        end

        it 'prints the description for each lint' do
          subject
          descriptions.each do |description|
            output.scan(/#{description}/).count.should == 1
          end
        end
      end
    end
  end

  describe '#display_report' do
    subject { reporter.display_report(report) }

    context 'when there are no lints' do
      let(:lints) { [] }

      it 'prints the summary' do
        subject
        output.should == "\n1 file inspected, 0 lints detected\n"
      end

      context 'when summaries are disabled in the logger' do
        let(:logger) { HamlLint::Logger.new(io, summary: false) }

        it 'prints nothing' do
          subject
          output.should == ''
        end
      end
    end

    context 'when there are lints' do
      let(:filenames)    { ['some-filename.haml', 'other-filename.haml'] }
      let(:lines)        { [502, 724] }
      let(:descriptions) { ['Description of lint 1', 'Description of lint 2'] }
      let(:severities)   { [:warning] * 2 }
      let(:correcteds)   { [false, false] }
      let(:linter)       { double(name: 'SomeLinter') }

      let(:lints) do
        filenames.each_with_index.map do |filename, index|
          HamlLint::Lint.new(linter, filename, lines[index], descriptions[index],
                             severities[index], corrected: correcteds[index])
        end
      end

      it 'prints the summary' do
        subject
        output.should == "\n2 files inspected, 2 lints detected\n"
      end

      context 'with a corrected lint' do
        let(:correcteds) { [false, true] }

        it 'prints the summary' do
          subject
          output.should == "\n2 files inspected, 2 lints detected, 1 lint corrected\n"
        end
      end
    end
  end
end
