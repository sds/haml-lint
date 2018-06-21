require 'spec_helper'

describe HamlLint::Linter::Syntax do
  let(:base_options) { { reporter: reporter } }
  let(:options) { base_options }
  let(:reporter) { HamlLint::Reporter::HashReporter.new(StringIO.new) }
  let(:runner) { HamlLint::Runner.new }
  let(:filename) { 'syntax_text.haml' }

  include_context 'isolated environment'

  before do
    `echo "#{haml}" > #{filename}`
    runner.stub(:extract_applicable_files).and_return([filename])
  end

  subject { runner.run(options) }

  context 'when RuboCop linter is disabled' do
    let(:options) { base_options.merge excluded_linters: %w(RuboCop) }

    context 'when syntax is valid' do
      let(:haml) { '%tag{ a: "A", b: "B" }' }

      it 'adds a syntax lint to the output' do
        subject.lints.size.should == 0
      end
    end

    # context 'when there are invalid hash attributes' do
    #   let(:haml) { '%tag{ a: "A" b: "B" }' }
    #
    #   it { should report_syntax_lint }
    #   it { should report_on_line 2 }
    #   it { should report_message /unexpected token/ }
    #   it { should report_severity :error }
    # end

    context 'when there is an indentation syntax error' do
      let(:haml) { "%div\n  %span Hello, world\n\t%span Goodnight, moon" }

      it { should report_syntax_lint }
      it { should report_on_line 2 }
      it { should report_message /^Inconsistent indentation/ }
      it { should report_severity :error }
    end
  end
end

RSpec::Matchers.define :report_syntax_lint do
  match do |report|
    report.lints.size == 1 && report.lints.first.linter.name == 'Syntax'
  end
end

RSpec::Matchers.define :report_on_line do |expected_line_number|
  match do |report|
    report.lints.size == 1 && expected_line_number == report.lints.first.line
  end
end

RSpec::Matchers.define :report_message do |expected_message|
  match do |report|
    report.lints.size == 1 && expected_message === report.lints.first.message
  end
end

RSpec::Matchers.define :report_severity do |expected_severity|
  match do |report|
    report.lints.size == 1 && report.lints.first.severity == expected_severity
  end
end
