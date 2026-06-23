# frozen_string_literal: true

describe HamlLint::Linter::UnnecessaryInterpolation do
  include_context 'linter'

  context 'when tag contains inline text without interpolation' do
    let(:haml) { '%tag Some inline text' }
    it { should_not report_lint }
  end

  context 'when tag contains inline text with some interpolation' do
    let(:haml) { '%tag Some #{interpolated} text' }
    it { should_not report_lint }
  end

  context 'when tag contains inline text with interpolation at the start' do
    let(:haml) { '%tag #{interpolation} -- #{more_interpolation}' }
    it { should_not report_lint }
  end

  context 'when tag contains inline text with only interpolation' do
    let(:haml) { '%tag #{only_interpolation}' }
    it { should report_lint }
  end

  context 'when tag contains nested content' do
    let(:haml) { <<-HAML }
      %tag
        \#{some_interpolation}
    HAML
    it { should_not report_lint }
  end

  context 'when a non-interpolated 2-char variable is used' do
    let(:haml) { '%tag= ab' }
    it { should_not report_lint }
  end

  context 'with autocorrect' do
    let(:autocorrect) { :safe }

    context 'when the tag content is a single interpolation' do
      let(:haml) { '%tag #{foo}' }

      it 'rewrites it as inline script' do
        subject
        document.source.should == '%tag= foo'
      end

      it 'records the lint as corrected' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == true
      end
    end

    context 'when the tag has static classes and ids' do
      let(:haml) { '%tag.cls#id #{foo}' }

      it 'rewrites it as inline script' do
        subject
        document.source.should == '%tag.cls#id= foo'
      end
    end

    context 'when the tag has an attribute hash' do
      let(:haml) { '%tag{a: 1} #{foo}' }

      it 'rewrites it as inline script' do
        subject
        document.source.should == '%tag{a: 1}= foo'
      end
    end

    context 'when the interpolation expression contains a method call' do
      let(:haml) { '%tag #{user.name}' }

      it 'preserves the expression' do
        subject
        document.source.should == '%tag= user.name'
      end
    end

    context 'when the interpolation expression contains quoted characters' do
      let(:haml) { "%tag \#{t('.x')}" }

      it 'preserves the expression' do
        subject
        document.source.should == "%tag= t('.x')"
      end
    end

    context 'when the content is an explicit pure-interpolation string' do
      let(:haml) { '%tag= "#{foo}"' }

      it 'rewrites it without the interpolation wrapper' do
        subject
        document.source.should == '%tag= foo'
      end
    end

    context 'when the tag has mixed inline content' do
      let(:haml) { '%tag Some #{x} text' }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled inline' do
      let(:haml) { "-# haml-lint:disable UnnecessaryInterpolation\n%tag \#{foo}" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'under :all mode' do
      let(:autocorrect) { :all }
      let(:haml) { '%tag #{foo}' }

      it 'also rewrites it as inline script' do
        subject
        document.source.should == '%tag= foo'
      end
    end
  end
end
