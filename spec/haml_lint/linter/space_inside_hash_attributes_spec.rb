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
