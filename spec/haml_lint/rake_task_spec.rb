require 'spec_helper'
require 'haml_lint/rake_task'

describe HamlLint::RakeTask do
  before do
    # Silence console output
    # STDOUT.stub(:write)
  end

  describe '#run' do
    subject do
      HamlLint::RakeTask.new
      Rake::Task['haml_lint']
    end

    it 'returns a successful exit code' do
      expect(subject.invoke).to be_truthy
    end
  end
end
