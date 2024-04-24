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

  describe '.block_keyword' do
    it 'should work for empty strings' do
      expect(described_class.block_keyword('')).to eq(nil)
      expect(described_class.block_keyword('             ')).to eq(nil)
    end

    it 'should extract keywords from simple input' do
      # Cases where we can use `<keyword> value`
      %w[if unless case].each do |keyword|
        input = <<~HAML
          - #{keyword} foobar
            = foo
        HAML

        expect(described_class.block_keyword(input)).to eq(keyword)
      end

      # Case for the `begin` keyword
      begin_input = <<~HAML
        - begin
      HAML

      expect(described_class.block_keyword(begin_input)).to eq('begin')

      # Case for the `for` keyword
      for_input = <<~HAML
        for user in User.all do
      HAML

      expect(described_class.block_keyword(for_input)).to eq('for')

      # Cases where we can use `<keyword> value do`
      %w[until while].each do |keyword|
        input = <<~HAML
          #{keyword} foobar do
        HAML

        expect(described_class.block_keyword(input)).to eq(keyword)
      end
    end

    it 'should not raise exception when keyword is used as keyword argument' do
      # Everything on single line, should work
      input_single_line = '= helper foo: true, bar: true, if: false'
      expect(described_class.block_keyword(input_single_line)).to eq(nil)

      # Keyword as symbol not first on new line should work
      input_multiline_1 = <<~HAML
        = helper foo: true,
                 bar: true, if: false
      HAML
      expect(described_class.block_keyword(input_multiline_1)).to eq(nil)

      # Keyword as symbol first on new line should also work
      input_multiline_2 = <<~HAML
        = helper foo: true, bar: true,
                 if: false
      HAML
      expect(described_class.block_keyword(input_multiline_2)).to eq(nil)

      # Testing with another keyword
      input_multiline_3 = <<~HAML
        = helper foo: true, bar: true,
                 for: User.first
      HAML
      expect(described_class.block_keyword(input_multiline_3)).to eq(nil)
    end
  end
end
