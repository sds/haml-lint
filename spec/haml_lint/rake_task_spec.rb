require 'spec_helper'
require 'haml_lint/rake_task'
require 'tempfile'

describe HamlLint::RakeTask do
  before(:all) do
    HamlLint::RakeTask.new do |t|
      t.quiet = true
    end
  end

  let(:file) do
    Tempfile.new(%w[haml-file .haml]).tap do |f|
      f.write(haml)
      f.close
    end
  end

  def run_task
    Rake::Task[:haml_lint].reenable # Allows us to execute task multiple times
    Rake::Task[:haml_lint].invoke(file.path)
  end

  context 'when HAML document is valid' do
    let(:haml) { '%tag' }

    it 'executes without error' do
      expect { run_task }.not_to raise_error
    end
  end

  context 'when HAML document is invalid' do
    let(:haml) { "%tag\n  %foo\n      %bar" }

    it 'raises an error' do
      expect { run_task }.to raise_error
    end
  end
end
