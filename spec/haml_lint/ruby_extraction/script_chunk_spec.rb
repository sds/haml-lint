# frozen_string_literal: true

describe HamlLint::RubyExtraction::ScriptChunk do
  describe '.format_ruby_lines_to_haml_lines' do
    def do_test
      generated_haml = described_class.format_ruby_lines_to_haml_lines(ruby.split("\n"),
                                                                       script_output_ruby_prefix: 'HL.out = ')
      expect(generated_haml.join("\n")).to eq(expected_haml.chop)
    end

    context 'with a begin and rescue' do
      let(:ruby) { <<~RUBY }
        begin
          foo = 1
        rescue StandardError => e
          foo = 2
        end
      RUBY

      let(:expected_haml) { <<~HAML }
        - begin
          - foo = 1
        - rescue StandardError => e
          - foo = 2
      HAML

      it { do_test }
    end

    context 'with a rescue without preceding begin' do
      let(:ruby) { <<~RUBY }
          foo = 1
        rescue StandardError => e
          foo = 2
        end
      RUBY

      let(:expected_haml) { <<~HAML }
          - foo = 1
        - rescue StandardError => e
          - foo = 2
      HAML

      it { do_test }
    end

    context 'with a ensure without preceding begin' do
      let(:ruby) { <<~RUBY }
          foo = 1
        ensure
          foo = 2
        end
      RUBY

      let(:expected_haml) { <<~HAML }
          - foo = 1
        - ensure
          - foo = 2
      HAML

      it { do_test }
    end

    context 'with a elsif without preceding if' do
      let(:ruby) { <<~RUBY }
          HL.out = "hi"
        elsif abc?
          HL.out = "world"
      RUBY

      let(:expected_haml) { <<~HAML }
          = "hi"
        - elsif abc?
          = "world"
      HAML

      it { do_test }
    end

    context 'with a else without preceding if' do
      let(:ruby) { <<~RUBY }
          foo()
        else
          bar()
      RUBY

      let(:expected_haml) { <<~HAML }
          - foo()
        - else
          - bar()
      HAML

      it { do_test }
    end

    context 'with a else, end, else without preceding if' do
      let(:ruby) { <<~RUBY }
            foo()
          else
            bar()
          end.join
        else
          more()
      RUBY

      let(:expected_haml) { <<~HAML }
            - foo()
          - else
            - bar()
          - end.join
        - else
          - more()
      HAML

      it { do_test }
    end

    context 'with a when without preceding case' do
      let(:ruby) { <<~RUBY }
          foo()
        when 123
          bar()
      RUBY

      let(:expected_haml) { <<~HAML }
          - foo()
        - when 123
          - bar()
      HAML

      it { do_test }
    end

    context 'with consecutive multiline method calls' do
      let(:ruby) { <<~RUBY }
        foo(
        )
        foo(
        )
      RUBY

      let(:expected_haml) { <<~HAML }
        - foo( |
          ) |

        - foo( |
          ) |
      HAML

      it { do_test }
    end

    context 'with multiline method call followed by block with arguments and spaces' do
      let(:ruby) { <<~RUBY }
        foo(
        )
        hello do | hi |
      RUBY

      let(:expected_haml) { <<~HAML }
        - foo( |
          ) |
        - hello do | hi |
      HAML

      it { do_test }
    end
  end
end
