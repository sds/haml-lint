# frozen_string_literal: true

describe HamlLint::Linter::ImplicitDiv do
  include_context 'linter'

  context 'when a div tag has no classes or IDs' do
    let(:haml) { <<-HAML }
      %div Hello
    HAML

    it { should_not report_lint }
  end

  context 'when a div tag has a class' do
    let(:haml) { <<-HAML }
      %div.container Hello
    HAML

    it { should report_lint line: 1 }
  end

  context 'when a div has an ID' do
    let(:haml) { <<-HAML }
      %div#container Hello
    HAML

    it { should report_lint line: 1 }
  end

  context 'when a nameless tag has a class' do
    let(:haml) { <<-HAML }
      .container Hello
    HAML

    it { should_not report_lint }
  end

  context 'when a nameless tag has an ID' do
    let(:haml) { <<-HAML }
      #container Hello
    HAML

    it { should_not report_lint }
  end

  context 'when a div with a class is deeply nested' do
    let(:haml) { <<-HAML }
      %tag
        %child
          %div.container
    HAML

    it { should report_lint line: 3 }
  end

  context 'when a div has ruby code inside curly braces' do
    let(:haml) { <<-HAML }
      %div{ id: Object.to_s }
    HAML

    it { should_not report_lint }
  end

  context 'when div has ruby code inside square braces' do
    let(:haml) { <<-HAML }
      %div[Object.to_s]
    HAML

    it { should_not report_lint }
  end

  context 'with autocorrect' do
    let(:autocorrect) { :safe }

    context 'when a div tag has a class' do
      let(:haml) { '%div.container Hello' }

      it 'removes the implicit div' do
        subject
        document.source.should == '.container Hello'
      end

      it 'records the lint as corrected' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == true
      end
    end

    context 'when a div tag has an ID' do
      let(:haml) { '%div#container Hello' }

      it 'removes the implicit div' do
        subject
        document.source.should == '#container Hello'
      end
    end

    context 'when a div tag has classes, an ID and content' do
      let(:haml) { '%div.foo#bar Hello' }

      it 'removes only the implicit div, preserving classes, ID and content' do
        subject
        document.source.should == '.foo#bar Hello'
      end
    end

    context 'when the div is nested' do
      let(:haml) { <<-HAML }
        %tag
          %child
            %div.container
      HAML

      it 'removes the implicit div while preserving indentation' do
        subject
        document.source.should == "%tag\n  %child\n    .container\n"
      end
    end

    context 'when there is no explicit div to remove' do
      let(:haml) { '.container Hello' }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled' do
      let(:haml) { "-# haml-lint:disable ImplicitDiv\n%div.foo" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'under :all mode' do
      let(:autocorrect) { :all }
      let(:haml) { '%div.container Hello' }

      it 'also removes the implicit div' do
        subject
        document.source.should == '.container Hello'
      end
    end
  end
end
