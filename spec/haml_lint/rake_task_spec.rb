require 'spec_helper'
require 'haml_lint/rake_task'
require 'tempfile'

describe HamlLint::RakeTask do
  let(:task) { HamlLint::RakeTask.new }

  before do
    Tempfile.new(%w[haml-file .haml]).tap do |f|
      f.write(haml)
      task.pattern = f.path
    end
  end

  describe '#run' do
    subject { Rake::Task['haml_lint'] }

    context 'when HAML document is valid' do
      let(:haml) { '%tag' }

      it 'returns a successful exit code' do
        expect(subject.invoke).to be_truthy
      end
    end

    context 'when HAML document is invalid' do
      let(:haml) { "%tag\n  %foo\n      %bar" }

      it 'returns a successful exit code' do
        expect(subject.invoke).to be_falsey
      end
    end
  end
end
