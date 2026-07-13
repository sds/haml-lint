# frozen_string_literal: true

describe HamlLint::Linter::HtmlAttributes do
  include_context 'linter'

  context 'when a tag has no attributes' do
    let(:haml) { '%tag' }

    it { should_not report_lint }
  end

  context 'when a tag contains hash attributes' do
    let(:haml) { "%tag{ lang: 'en' }" }

    it { should_not report_lint }
  end

  context 'when a tag contains HTML attributes' do
    let(:haml) { '%tag(lang=en)' }

    it { should report_lint }
  end

  context 'when a tag contains HTML attributes and hash attributes' do
    let(:haml) { '%tag(lang=en){ attr: value }' }

    it { should report_lint }
  end

  context 'with autocorrect' do
    let(:autocorrect) { :all }

    context 'when a tag has a single dynamic HTML attribute' do
      let(:haml) { '%tag(lang=en)' }

      it 'rewrites it using the hash attributes syntax' do
        subject
        document.source.should == '%tag{ "lang" => en }'
      end

      it 'records the lint as corrected' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == true
      end
    end

    context 'when a tag has multiple static HTML attributes' do
      let(:haml) { '%a(href="x" title="foo")' }

      it 'rewrites all of them' do
        subject
        document.source.should == '%a{ "href" => "x", "title" => "foo" }'
      end
    end

    context 'when a tag has a boolean HTML attribute' do
      let(:haml) { '%input(type="text" required)' }

      it 'rewrites the boolean attribute as `true`' do
        subject
        document.source.should == '%input{ "type" => "text", "required" => true }'
      end
    end

    context 'when a tag mixes static and dynamic HTML attributes' do
      let(:haml) { '%a(href="x" data=dynamic)' }

      it 'preserves the Ruby expression for the dynamic value' do
        subject
        document.source.should == '%a{ "href" => "x", "data" => dynamic }'
      end
    end

    context 'when an attribute name contains a dash' do
      let(:haml) { '%div(data-foo="bar")' }

      it 'keeps the string key' do
        subject
        document.source.should == '%div{ "data-foo" => "bar" }'
      end
    end

    context 'when the tag uses the class/id shorthand' do
      let(:haml) { '%div.card(data-x="y")' }

      it 'reports the lint but does not change the source' do
        subject
        subject.lints.first.corrected.should == false
        document.source_was_changed.should == false
      end
    end

    context 'when the tag already has a hash attributes group' do
      let(:haml) { '%tag(lang=en){ attr: value }' }

      it 'reports the lint but does not change the source' do
        subject
        subject.lints.first.corrected.should == false
        document.source_was_changed.should == false
      end
    end

    context 'under :safe mode' do
      let(:autocorrect) { :safe }
      let(:haml) { '%tag(lang=en)' }

      it 'reports the lint but does not correct it' do
        subject
        subject.lints.first.corrected.should == false
        document.source_was_changed.should == false
      end
    end

    context 'when there is nothing to correct' do
      let(:haml) { "%tag{ lang: 'en' }" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled inline' do
      let(:haml) { "-# haml-lint:disable HtmlAttributes\n%tag(lang=en)" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end
  end
end
