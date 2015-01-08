require 'spec_helper'
require 'haml_lint/rake_task'

describe HamlLint::RakeTask do
  before do
    @task = HamlLint::RakeTask.new
  end

  describe '#run' do
    subject do
      Rake::Task['haml_lint']
    end

    it 'returns a successful exit code' do
      @task.pattern = __FILE__

      expect(subject.invoke).to be_truthy
    end
  end
end
