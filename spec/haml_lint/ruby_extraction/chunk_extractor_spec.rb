# frozen_string_literal: true

describe HamlLint::RubyExtraction::ChunkExtractor do
  let(:options) do
    {
      config: HamlLint::ConfigurationLoader.default_configuration,
    }
  end

  let(:document) { HamlLint::Document.new(normalize_indent(haml), options) }
  let(:extractor) do
    described_class.new(document, script_output_prefix: 'HL.out = ').tap(&:prepare_extract)
  end

  describe '#extract_raw_ruby_lines' do
    def do_test
      expect(ruby_from_haml).to eq(expected_ruby_from_haml)
      expect(extractor.extract_raw_ruby_lines(ruby_from_haml, 0)).to eq(expected_return)
    end

    context 'with a silent script' do
      let(:ruby_from_haml) do
        document.tree.children.first.script
      end

      context 'single-line' do
        let(:haml) { <<~HAML }
          - foo(bar: 42, spam: "hello")
        HAML

        let(:expected_ruby_from_haml) { <<~CODE.rstrip }
          \ foo(bar: 42, spam: "hello")
        CODE

        let(:expected_return) { [2, <<~RET.split("\n")] }
          foo(bar: 42, spam: "hello")
        RET

        it { do_test }
      end

      context 'multi-line using a comma' do
        let(:haml) { <<~HAML }
          - foo(bar: 42,
                spam: "hello")
        HAML

        let(:expected_ruby_from_haml) { <<~CODE.rstrip }
          \ foo(bar: 42, spam: "hello")
        CODE

        let(:expected_return) { [2, <<~RET.split("\n")] }
          foo(bar: 42,\n      spam: "hello")
        RET

        it { do_test }
      end

      context 'multi-line using a pipe' do
        let(:haml) { <<~HAML }
          - foo(bar: 42, spam: |
                "hello") |
        HAML

        let(:expected_ruby_from_haml) { <<~CODE.rstrip }
          \ foo(bar: 42, spam: "hello")
        CODE

        let(:expected_return) { [2, <<~RET.split("\n")] }
          foo(bar: 42, spam:\n      "hello")
        RET

        it { do_test }
      end

      context 'multi-line using a pipe then a comma' do
        let(:haml) { <<~HAML }
          - foo(bar: |
                42, |
                spam: "hello")
        HAML

        let(:expected_ruby_from_haml) { <<~CODE.rstrip }
          \ foo(bar: 42, spam: "hello")
        CODE

        let(:expected_return) { [2, <<~RET.split("\n")] }
          foo(bar:\n      42,\n      spam: "hello")
        RET

        it { do_test }
      end
    end
  end

  describe '#extract_raw_tag_attributes_ruby_lines' do
    context 'with a tag attributes' do
      def do_test
        expect(ruby_from_haml).to eq(expected_ruby_from_haml)
        expect(extractor.extract_raw_tag_attributes_ruby_lines(ruby_from_haml, 0)).to eq(expected_return)
      end

      let(:ruby_from_haml) do
        document.tree.children.first.dynamic_attributes_sources.first
      end

      context 'hash-like' do
        context 'single-line' do
          let(:haml) { <<~HAML }
            %tag{foo: bar}
          HAML

          let(:expected_ruby_from_haml) { <<~CODE.rstrip }
            foo: bar
          CODE

          let(:expected_return) { [5, <<~RET.split("\n")] }
            foo: bar
          RET

          it { do_test }
        end

        context 'multi-line with comma' do
          let(:haml) { <<~HAML }
            %tag{foo: bar,
                 abc: "hello"}
          HAML

          let(:expected_ruby_from_haml) { <<~CODE.rstrip }
            foo: bar,
            abc: "hello"
          CODE

          let(:expected_return) { [5, <<~RET.split("\n")] }
            foo: bar,
                 abc: "hello"
          RET

          it { do_test }
        end

        context 'multi-line with pipe' do
          let(:haml) { <<~HAML }
            %tag{foo: |
                 bar, abc: "hello"} |

          HAML

          let(:expected_ruby_from_haml) { <<~CODE.rstrip }
            foo: bar, abc: "hello"
          CODE

          let(:expected_return) { [5, <<~RET.split("\n")] }
            foo:
                 bar, abc: "hello"
          RET

          it { do_test }
        end

        context 'multi-line using a pipe then a comma' do
          let(:haml) { <<~HAML }
            %tag{foo: |
                 bar, |
                 abc: "hello"}
          HAML

          let(:expected_ruby_from_haml) { <<~CODE.rstrip }
            foo: bar,#{' '}
            abc: "hello"
          CODE

          let(:expected_return) { [5, <<~RET.split("\n")] }
            foo:
                 bar,
                 abc: "hello"
          RET

          it { do_test }
        end

        # This is supported for tag attributes only...
        context 'multi-line without pipe or comma' do
          let(:haml) { <<~HAML }
            %span{ foo:
                "bar",
                spam:
                42 }
          HAML

          let(:expected_ruby_from_haml) { <<~CODE.chop }
            \ foo:
            "bar",
            spam:
            42#{' '}
          CODE

          let(:expected_return) { [6, <<~RET.split("\n")] }
            \ foo:
                "bar",
                spam:
                42#{' '}
          RET

          it {
            if HamlLint::VersionComparer.for_haml < '5.2'
              skip
            end
            do_test
          }
        end
      end
    end
  end
end
