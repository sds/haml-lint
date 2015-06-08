require 'spec_helper'

describe HamlLint::Reporter::JsonReporter do
  describe '#display_report' do
    let(:io) { StringIO.new }
    let(:output) { JSON.parse(io.string) }
    let(:logger) { HamlLint::Logger.new(io) }
    let(:report) { HamlLint::Report.new(lints, []) }
    let(:reporter) { described_class.new(logger) }

    subject { reporter.display_report(report) }

    shared_examples_for 'output format specification' do
      it 'matches the output specification' do
        subject
        output['metadata']['haml_lint_version'].should_not be_empty
        output['metadata']['ruby_engine'].should eq RUBY_ENGINE
        output['metadata']['ruby_patchlevel'].should eq RUBY_PATCHLEVEL.to_s
        output['metadata']['ruby_platform'].should eq RUBY_PLATFORM.to_s
        output['files'].should be_a_kind_of(Array)
        output['summary']['offense_count'].should be_a_kind_of(Integer)
        output['summary']['target_file_count'].should be_a_kind_of(Integer)
        output['summary']['inspected_file_count'].should be_a_kind_of(Integer)
      end
    end

    context 'when there are no lints' do
      let(:lints) { [] }
      let(:files) { [] }

      it 'list of files is empty' do
        subject
        output['files'].should be_empty
      end

      it 'number of target files is zero' do
        subject
        output['summary']['target_file_count'].should == 0
      end

      it_behaves_like 'output format specification'
    end

    context 'when there are lints' do
      let(:filenames)    { ['some-filename.haml', 'other-filename.haml'] }
      let(:lines)        { [502, 724] }
      let(:descriptions) { ['Description of lint 1', 'Description of lint 2'] }
      let(:severities)   { [:warning, :error] }

      let(:lints) do
        filenames.each_with_index.map do |filename, index|
          HamlLint::Lint.new(nil, filename, lines[index], descriptions[index], severities[index])
        end
      end

      it 'list of files contains files with offenses' do
        subject
        output['files'].map { |f| f['path'] }.sort.should eq filenames.sort
      end

      it_behaves_like 'output format specification'
    end
  end
end
