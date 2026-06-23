# frozen_string_literal: true

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

  context 'when a comment has a banner line' do
    let(:haml) { <<-HAML }
      -######################
      -# Important section! #
      -######################
    HAML

    it { should_not report_lint }
  end

  context 'with autocorrect' do
    let(:autocorrect) { :safe }

    context 'when a comment has no leading space' do
      let(:haml) { '-#A comment with no space' }

      it 'inserts a space after the marker' do
        subject
        document.source.should == '-# A comment with no space'
      end

      it 'records the lint as corrected' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == true
      end
    end

    context 'when a comment uses multiple `#` without a space' do
      let(:haml) { '-##A comment' }

      it 'inserts a space after the last marker' do
        subject
        document.source.should == '-## A comment'
      end
    end

    context 'when a comment already has a leading space' do
      let(:haml) { '-# A comment' }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled' do
      let(:haml) { "-# haml-lint:disable LeadingCommentSpace\n-#A comment" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'under :all mode' do
      let(:autocorrect) { :all }
      let(:haml) { '-#A comment' }

      it 'also inserts a space' do
        subject
        document.source.should == '-# A comment'
      end
    end
  end
end
