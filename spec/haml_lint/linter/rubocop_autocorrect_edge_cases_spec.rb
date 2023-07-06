# frozen_string_literal: true

describe HamlLint::Linter::RuboCop do
  context 'autocorrect edge cases' do
    include_context 'rubocop_autocorrect'
    let(:stub_rubocop?) { false }

    context 'handles end.something in corrected code' do
      let(:steps_string) { <<~TEXT }
        - foo(:bar => 123).map { |x| x ? (spam ? hello : world) : test }.join(', ')
        ---
        haml_lint_marker_1
        foo(:bar => 123).map { |x| x ? (spam ? hello : world) : test }.join(', ')
        haml_lint_marker_3
        ---
        haml_lint_marker_1
        foo(bar: 123).map do |x|
          if x
            spam ? hello : world
          else
            test
          end
        end.join(', ')
        haml_lint_marker_3
        ---
        #{final_step_string}
      TEXT

      let(:final_step_string) do
        # HAML 5.2 allows end.join(', '), not those above
        if HamlLint::VersionComparer.for_haml < '6.0'
          <<~TEXT.strip
            - foo(bar: 123).map do |x|
              - if x
                - spam ? hello : world
              - else
                - test
            - end.join(', ')
          TEXT
        else
          "- foo(:bar => 123).map { |x| x ? (spam ? hello : world) : test }.join(', ')"
        end
      end

      it { follows_steps }
    end

    context 'handles a if with a trailing space' do
      let(:steps_string) { <<~TEXT }
        - if a#{' '}
          abc
        ---
        haml_lint_marker_1
        if a
          haml_lint_marker_3
          haml_lint_plain_4 $$2
        end
        ---
        SKIP
        ---
        - if a
          abc
      TEXT

      it { follows_steps }
    end

    context 'handles a block with no arguments and a trailing space' do
      let(:steps_string) { <<~TEXT }
        - [].each do#{' '}
          abc
        ---
        haml_lint_marker_1
        [].each do
          haml_lint_marker_3
          haml_lint_plain_4 $$2
        end
        ---
        SKIP
        ---
        - [].each do
          abc
      TEXT

      it { follows_steps }
    end

    # Had a bug where the trailing space made the ChunkExtractor skip a `end`
    context 'handles a block with arguments and a trailing space' do
      let(:steps_string) { <<~TEXT }
        - [].each do |foo|#{' '}
          = foo
        ---
        haml_lint_marker_1
        [].each do |foo|
          HL.out = foo $$2
        end
        haml_lint_marker_5
        ---
        SKIP
        ---
        - [].each do |foo|
          = foo
      TEXT

      it { follows_steps }
    end

    context 'Does nothing if the markers get reordered' do
      let(:start_haml) { <<~HAML }
        - unless foo(:bar =>  123)
          hello
        - else
          world
      HAML

      let(:end_haml) { <<~HAML }
        - unless foo(:bar =>  123)
          hello
        - else
          world
      HAML

      it do
        # We disable autocorrect for Style/UnlessElse because of its reordering behavior, which we don't support.
        # This test stubs in Style/UnlessElse's behavior is to verify that things behave as expected if another
        # cop was to do this behavior.
        subject.stub(:process_ruby_source).and_return(<<~FORCED_RUBY)
          haml_lint_marker_1
          if foo(bar: 123)
            haml_lint_marker_7
            haml_lint_plain_8
          else
            haml_lint_marker_3
            haml_lint_plain_4
            haml_lint_marker_5
          end
        FORCED_RUBY

        subject.run_or_raise(document, autocorrect: autocorrect)

        matcher = eq(end_haml)
        document.source.should(
          matcher,
          -> { "Final HAML is different from expected. #{matcher.failure_message}\n#{format_lints}" }
        )

        haml_different = start_haml != end_haml
        document.source_was_changed.should == haml_different
      end
    end

    context 'handle end.join in input content for HAML < 6' do
      next if HamlLint::VersionComparer.for_haml >= '6'

      let(:start_haml) { <<~HAML }
        - if foo
          - [1,  2,  3]
        - end.join
      HAML

      let(:end_haml) { <<~HAML }
        - if foo
          - [1, 2, 3]
        - end.join
      HAML

      it do
        subject.run_or_raise(document, autocorrect: autocorrect)

        matcher = eq(end_haml)
        document.source.should(
          matcher,
          -> { "Final HAML is different from expected. #{matcher.failure_message}\n#{format_lints}" }
        )

        haml_different = start_haml != end_haml
        document.source_was_changed.should == haml_different
      end
    end

    # TO TEST: %tag #{expression}
  end
end
