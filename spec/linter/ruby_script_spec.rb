require 'spec_helper'

describe HamlLint::Linter::RubyScript do
  let(:output)    { nil }
  let(:has_lints) { true }

  # Need this block before including linter context so that stubbing occurs
  # before linter is run
  before { subject.stub(:run_ruby_linter).and_return([output, has_lints]) }

  include_context 'linter'

  let(:haml) { <<-HAML }
    %span To be
    %span= "or not"
    %span to be
  HAML

  context 'when the Ruby linter does not report any lints' do
    let(:has_lints) { false }
    it { should_not report_lint }
  end

  context 'when the Ruby linter reports lints' do
    let(:output) { 'somefile.rb:1 A lint description' }

    it 'uses the source map to transform line numbers' do
      subject.should report_lint line: 2
    end
  end
end
