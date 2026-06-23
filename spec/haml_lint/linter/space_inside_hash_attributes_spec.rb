# frozen_string_literal: true

describe HamlLint::Linter::SpaceInsideHashAttributes do
  include_context 'linter'

  context 'when a tag has no attributes' do
    let(:haml) { '%tag' }

    context 'default config (space)' do
      it { should_not report_lint }
    end

    context 'with no_space config' do
      let(:config) { super().merge('style' => 'no_space') }
      it { should_not report_lint }
    end
  end

  context 'when a tag contains hash attributes with a single leading and trailing space' do
    let(:haml) { "%tag{ lang: 'en' }" }

    context 'default config (space)' do
      it { should_not report_lint }
    end

    context 'with no_space config' do
      let(:config) { super().merge('style' => 'no_space') }
      it { should report_lint }
    end
  end

  context 'when a tag contains hash attributes without leading or trailing spaces' do
    let(:haml) { "%tag{lang: 'en'}" }

    context 'default config (space)' do
      it { should report_lint }
    end

    context 'with no_space config' do
      let(:config) { super().merge('style' => 'no_space') }
      it { should_not report_lint }
    end
  end

  context 'when an implicit-div tag contains hash attributes without leading or trailing spaces' do
    let(:haml) { ".some_class{lang: 'en'}" }

    context 'default config (space)' do
      it { should report_lint }
    end

    context 'with no_space config' do
      let(:config) { super().merge('style' => 'no_space') }
      it { should_not report_lint }
    end
  end

  context 'when a tag contains hash attributes without a leading space but with a trailing space' do
    let(:haml) { "%tag{lang: 'en' }" }

    context 'default config (space)' do
      it { should report_lint }
    end

    context 'with no_space config' do
      let(:config) { super().merge('style' => 'no_space') }
      it { should report_lint }
    end
  end

  context 'when a tag contains hash attributes with a leading space but without a trailing space' do
    let(:haml) { "%tag{ lang: 'en'}" }

    context 'default config (space)' do
      it { should report_lint }
    end

    context 'with no_space config' do
      let(:config) { super().merge('style' => 'no_space') }
      it { should report_lint }
    end
  end

  context 'when a tag contains hash attributes with two leading spaces and one trailing space' do
    let(:haml) { "%tag{  lang: 'en' }" }

    context 'default config (space)' do
      it { should report_lint }
    end

    context 'with no_space config' do
      let(:config) { super().merge('style' => 'no_space') }
      it { should report_lint }
    end
  end

  context 'when a tag contains hash attributes with one leading space and two trailing spaces' do
    let(:haml) { "%tag{ lang: 'en'  }" }

    context 'default config (space)' do
      it { should report_lint }
    end

    context 'with no_space config' do
      let(:config) { super().merge('style' => 'no_space') }
      it { should report_lint }
    end
  end

  # Multiline attributes were introduced in 5.2.1
  if Haml::VERSION >= '5.2.1'
    context 'when a tag contains multi-line attributes' do
      context 'with the first and last attributes on the same line as the brace and both separated by a space' do
        let(:haml) do
          <<~HAML
            .container
              %tag{ lang: 'en',
                near: true,
                last: 'one' }
          HAML
        end

        context 'default config (space)' do
          it { should_not report_lint }
        end

        context 'with no_space config' do
          let(:config) { super().merge('style' => 'no_space') }
          it { should report_lint }
        end
      end

      context 'with the first and last attribute on the same line as the brace without a leading space' do
        let(:haml) do
          <<~HAML
            .container
              %tag{lang: 'en',
                near: true,
                last: 'one' }
          HAML
        end

        context 'default config (space)' do
          it { should report_lint }
        end

        context 'with no_space config' do
          let(:config) { super().merge('style' => 'no_space') }
          it { should report_lint }
        end
      end

      context 'with the first and last attribute on the same line as the brace without a trailing space' do
        let(:haml) do
          <<~HAML
            .container
              %tag{ lang: 'en',
                near: true,
                last: 'one'}
          HAML
        end

        context 'default config (space)' do
          it { should report_lint }
        end

        context 'with no_space config' do
          let(:config) { super().merge('style' => 'no_space') }
          it { should report_lint }
        end
      end

      context 'with the first and last attribute on the same line as the brace without being separated by a space' do
        let(:haml) do
          <<~HAML
            .container
              %tag{lang: 'en',
                near: true,
                last: 'one'}
          HAML
        end

        context 'default config (space)' do
          it { should report_lint }
        end

        context 'with no_space config' do
          let(:config) { super().merge('style' => 'no_space') }
          it { should_not report_lint }
        end
      end

      context 'with the first and last attribute on a separate lines from the brace' do
        let(:haml) do
          <<~HAML
            .container
              %tag{
                lang: 'en',
                near: true,
                last: 'one'
              }
          HAML
        end

        context 'default config (space)' do
          it { should_not report_lint }
        end

        context 'with no_space config' do
          let(:config) { super().merge('style' => 'no_space') }
          it { should_not report_lint }
        end
      end
    end
  end

  context 'with autocorrect' do
    let(:autocorrect) { :safe }

    context 'default config (space)' do
      context 'when the braces have no padding' do
        let(:haml) { "%tag{lang: 'en'}" }

        it 'adds a space inside both braces' do
          subject
          document.source.should == "%tag{ lang: 'en' }"
        end

        it 'records the lints as corrected' do
          subject
          subject.lints.map(&:corrected).should == [true, true]
        end
      end

      context 'when only the trailing space is missing' do
        let(:haml) { "%tag{ lang: 'en'}" }

        it 'adds the missing trailing space only' do
          subject
          document.source.should == "%tag{ lang: 'en' }"
          subject.lints.size.should == 1
        end
      end

      context 'when there is extra padding' do
        let(:haml) { "%tag{  lang: 'en'  }" }

        it 'collapses to a single space inside each brace' do
          subject
          document.source.should == "%tag{ lang: 'en' }"
        end
      end
    end

    context 'with no_space config' do
      let(:config) { super().merge('style' => 'no_space') }
      let(:haml) { "%tag{ lang: 'en' }" }

      it 'removes the padding inside the braces' do
        subject
        document.source.should == "%tag{lang: 'en'}"
      end
    end

    context 'when already in the desired style' do
      let(:haml) { "%tag{ lang: 'en' }" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled' do
      let(:haml) { "-# haml-lint:disable SpaceInsideHashAttributes\n%tag{lang: 'en'}" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    if Haml::VERSION >= '5.2.1'
      context 'when the hash spans multiple lines' do
        let(:haml) { "%tag{lang: 'en',\n  near: true}" }

        it 'reports the lint without correcting it' do
          subject
          document.source_was_changed.should == false
          subject.lints.first.corrected.should == false
        end
      end
    end

    context 'under :all mode' do
      let(:autocorrect) { :all }
      let(:haml) { "%tag{lang: 'en'}" }

      it 'also normalizes the padding' do
        subject
        document.source.should == "%tag{ lang: 'en' }"
      end
    end
  end
end
