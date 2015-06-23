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
    Rake::Task[:haml_lint].tap do |t|
      t.reenable # Allows us to execute task multiple times
      t.invoke(file.path)
    end
  end

  context 'when Haml document is valid' do
    let(:haml) { "%p Hello world\n" }

    it 'executes without error' do
      expect { run_task }.not_to raise_error
    end
  end

  context 'when Haml document is invalid' do
    let(:haml) { "%tag\n  %foo\n      %bar" }

    it 'raises an error' do
      expect { run_task }.to raise_error
    end
  end
end
