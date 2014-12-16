require 'spec_helper'

describe HamlLint::Linter::LeadingCommentSpace do
  include_context 'linter'

  context 'when a comment has a leading space' do
    let(:haml) { '-# A comment with space' }

    it { should_not report_lint }
  end

  context 'when a comment has multiple leading spaces' do
    let(:haml) { '-#    A comment with multiple spaces' }

    it { should_not report_lint }
  end

  context 'when a comment has no leading space' do
    let(:haml) { '-#A comment with no space' }

    it { should report_lint }
  end

  context 'when a comment is on an empty line with no leading space' do
    let(:haml) { '-#' }

    it { should_not report_lint }
  end

  context 'when a comment spans multiple lines' do
    let(:haml) { <<-HAML }
      -#
        One line
        Two lines
    HAML

    it { should_not report_lint }
  end
end
