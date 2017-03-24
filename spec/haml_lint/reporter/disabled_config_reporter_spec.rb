require 'spec_helper'

RSpec.describe HamlLint::Reporter::DisabledConfigReporter do
  let(:config)   { File.read('.haml-lint_todo.yml') }
  let(:files)    { ['some-filename.haml'] }
  let(:io)       { StringIO.new }
  let(:output)   { io.string }
  let(:logger)   { HamlLint::Logger.new(io) }
  let(:report)   { HamlLint::Report.new(lints, files, reporter: reporter) }
  let(:reporter) { described_class.new(logger) }

  around do |example|
    directory { example.run }
  end

  describe '#display_report' do
    subject { reporter.display_report(report) }

    context 'when there are no lints' do
      let(:files) { ['some-filename.haml', 'other-filename.haml'] }
      let(:lints) { [] }

      it 'prints the summary' do
        subject
        output.should == "\n2 files inspected, 0 lints detected\n" \
          "Created .haml-lint_todo.yml.\n" \
          'Run `haml-lint --config .haml-lint_todo.yml`, or add '\
          "`inherits_from: .haml-lint_todo.yml` in a .haml-lint.yml file.\n"
      end

      it 'creates a file with just a header' do
        subject
        config.should == described_class::HEADING
      end
    end

    context 'when there are lints' do
      let(:files)        { ['some-filename.haml', 'some-filename.haml', 'other-filename.haml'] }
      let(:lines)        { [502, 504, 724] }
      let(:descriptions) { Array.new(3) { |i| "Description of lint #{i + 1}" } }
      let(:header)       { output.split("\n")[0..3].join("\n") }
      let(:linter)       { double(name: 'SomeLinter') }
      let(:offenses)     { output_without_summary.split("\n")[1..-1].join("\n") }
      let(:output_without_summary) { output.split("\n").reject(&:empty?)[0..-2].join("\n") }
      let(:severities)   { [:warning] * 3 }
      let(:summary)      { output.split("\n")[-4..-1].join("\n") }

      let(:lints) do
        files.each_with_index.map do |file, index|
          HamlLint::Lint.new(linter, file, lines[index], descriptions[index], severities[index])
        end
      end

      # This is a hack to get around the fact that the method isn't called in isolation
      before do
        linters_with_lints = { linter.name => files.uniq }
        linters_lint_count = { linter.name => lints.size }
        reporter.__send__(:instance_variable_set, :@linters_with_lints, linters_with_lints)
        reporter.__send__(:instance_variable_set, :@linters_lint_count, linters_lint_count)
      end

      it 'prints the header' do
        subject
        header.should == "\n\nOffenses:\n"
      end

      it 'prints each lint on its own line' do
        subject
        offenses.should == \
          "other-filename.haml:724 [W] SomeLinter: Description of lint 3\n" \
          "some-filename.haml:502 [W] SomeLinter: Description of lint 1\n" \
          "some-filename.haml:504 [W] SomeLinter: Description of lint 2\n" \
          "3 files inspected, 3 lints detected\n" \
          'Created .haml-lint_todo.yml.'
      end

      it 'prints the summary' do
        subject
        summary.should == "\n3 files inspected, 3 lints detected\n" \
          "Created .haml-lint_todo.yml.\n" \
          'Run `haml-lint --config .haml-lint_todo.yml`, or add '\
          '`inherits_from: .haml-lint_todo.yml` in a .haml-lint.yml file.'
      end

      it 'creates a file with the disabled configs' do
        subject
        config.should ==
          [
            described_class::HEADING,
            '',
            'linters:',
            '',
            '  # Offense count: 3',
            '  SomeLinter:',
            '    exclude:',
            '      - "some-filename.haml"',
            '      - "other-filename.haml"'
          ].join("\n")
      end
    end
  end

  describe '#finished_file' do
    subject { reporter.finished_file(file, lints) }

    context 'when there are no lints' do
      let(:file) { 'some-filename.haml' }
      let(:lints) { [] }

      it 'does not log any lints on linters' do
        expect { subject }.not_to change(reporter, :linters_with_lints)
      end

      it 'does not log any lint counts' do
        expect { subject }.not_to change(reporter, :linters_lint_count)
      end
    end

    context 'when there are lints' do
      let(:file) { 'some-filename.haml' }
      let(:lines)        { [502, 504, 724] }
      let(:descriptions) { Array.new(3) { |i| "Description of lint #{i + 1}" } }
      let(:header)       { output.split("\n")[0..3].join("\n") }
      let(:linter)       { double(name: 'SomeLinter') }
      let(:offenses)     { output_without_summary.split("\n")[1..-1].join("\n") }
      let(:output_without_summary) { output.split("\n").reject(&:empty?)[0..-2].join("\n") }
      let(:severities)   { [:warning] * 3 }
      let(:summary)      { output.split("\n")[-4..-1].join("\n") }

      let(:lints) do
        lines.each_with_index.map do |line, index|
          HamlLint::Lint.new(linter, file, line, descriptions[index], severities[index])
        end
      end

      it 'logs lints on the linters' do
        expect { subject }.to change(reporter, :linters_with_lints).to(
          'SomeLinter' => ['some-filename.haml']
        )
      end

      it 'logs any lint counts' do
        expect { subject }.to change(reporter, :linters_lint_count).to('SomeLinter' => 3)
      end
    end
  end
end
