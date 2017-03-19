require 'spec_helper'

describe HamlLint::Linter::SpaceBeforeScript do
  include_context 'linter'

  context 'when silent script has no separating space' do
    let(:haml) { <<-HAML }
      %span Hello
      -some_code
      %span World
    HAML

    it { should report_lint line: 2 }
  end

  context 'when silent script has a separating space' do
    let(:haml) { <<-HAML }
      %span Hello
      - some_code
      %span World
    HAML

    it { should_not report_lint }
  end

  context 'when script has no separating space' do
    let(:haml) { <<-HAML }
      %span Hello
      =some_code
      %span World
    HAML

    it { should report_lint line: 2 }
  end

  context 'when unsafe script has separating space' do
    let(:haml) { <<-HAML }
      %span Hello
      != some_code
      %span World
    HAML

    it { should_not report_lint }

    context 'and nested' do
      let(:haml) { <<-HAML }
        %span Hello
        %span
          != some_code
        %span World
      HAML

      it { should_not report_lint }
    end
  end

  context 'when unsafe script has no separating space' do
    let(:haml) { <<-HAML }
      %span Hello
      !=some_code
      %span World
    HAML

    it { should report_lint line: 2 }

    context 'and inline' do
      let(:haml) { <<-HAML }
        %span Hello
        %span!=some_code
        %span World
      HAML

      it { should report_lint line: 2 }
    end
  end

  context 'when escaping script has no separating space' do
    let(:haml) { <<-HAML }
      %span Hello
      &=some_code
      %span World
    HAML

    it { should report_lint line: 2 }

    context 'and inline' do
      let(:haml) { <<-HAML }
        %span Hello
        %span&=some_code
        %span World
      HAML

      it { should report_lint line: 2 }
    end
  end

  context 'when script has a separating space' do
    let(:haml) { <<-HAML }
      %span Hello
      = some_code
      %span World
    HAML

    it { should_not report_lint }
  end

  context 'when inline script has no separating space' do
    let(:haml) { <<-HAML }
      %span Hello
      %span='there'
      %span World
    HAML

    it { should report_lint line: 2 }

    context 'and is a comment' do
      let(:haml) { <<-HAML }
        %p=# A comment
        %p=#A comment
      HAML

      it { should_not report_lint }
    end
  end

  context 'when inline script has a separating space' do
    let(:haml) { <<-HAML }
      %span Hello
      %span= 'there'
      %span World
    HAML

    it { should_not report_lint }
  end

  context 'when inline script contains string that is the same as the tag' do
    let(:haml) { <<-HAML }
      %tag.count= count
    HAML

    it { should_not report_lint }
  end

  context 'when inline script spreads across multiple lines via comma' do
    context 'and the script has a separating space' do
      let(:haml) { <<-HAML }
        %tag= link_to 'Link',
                      path
      HAML

      it { should_not report_lint }
    end

    context 'and the script does not have a separating space' do
      let(:haml) { <<-HAML }
        %tag=link_to 'Link',
                     path
        %tag
      HAML

      it { should report_lint line: 1 }
    end
  end

  context 'when inline script spreads across multiple lines via vertical pipe' do
    context 'and the script has a separating space' do
      let(:haml) { <<-HAML }
        %tag= link_to 'Click' + |
                      'Here'    |
      HAML

      it { should_not report_lint }
    end

    context 'and the script has a separating space and vertical pipes are indented' do
      let(:haml) { <<-HAML }
        %tag= link_to 'Click',                                   |
                      'Here'                                     |
      HAML

      it { should_not report_lint }
    end

    context 'and the script does not have a separating space' do
      let(:haml) { <<-HAML }
        %tag=link_to 'Click' + |
                     'Here'    |
        %tag
      HAML

      it { should report_lint line: 1 }
    end
  end

  context 'when plain text contains interpolation' do
    let(:haml) { <<-HAML }
      %p
        Some \#{interpolated} text
    HAML

    it { should_not report_lint }
  end

  context 'when inline tag text contains interpolation' do
    let(:haml) { '%p Some #{interpolated} text' }

    it { should_not report_lint }
  end

  context 'when inline tag script contains quotes' do
    context 'and there is no separating space' do
      let(:haml) { '%p="Some #{interpolated} text"' }
      it { should report_lint }
    end

    context 'and there is a separating space' do
      let(:haml) { '%p= "Some #{interpolated} text"' }
      it { should_not report_lint }
    end
  end

  context 'when inline tag is nested in another tag' do
    let(:haml) { <<-HAML }
      %div
        %div
          %div= value
      %div= array[value]
    HAML

    it { should_not report_lint }

    context 'and the tag has siblings' do
      let(:haml) { <<-HAML }
        %div
          %div Hello
          %div= value
        = array[value]
      HAML

      it { should_not report_lint }
    end
  end
end
