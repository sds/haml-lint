require 'spec_helper'

describe HamlLint::Parser do
  context 'when skip_frontmatter is true' do
    let(:parser) { HamlLint::Parser.new(haml, 'skip_frontmatter' => true) }

    let(:haml) { normalize_indent(<<-HAML) }
      ---
      :key: value
      ---
      %tag
        Some non-inline text
      - 'some code'
    HAML

    it 'excludes the frontmatter' do
      expect(parser.contents).to eq(normalize_indent(<<-CONTENT))
        %tag
          Some non-inline text
        - 'some code'
      CONTENT
    end

    context 'when haml has --- as content' do
      let(:haml) { normalize_indent(<<-HAML) }
        ---
        :key: value
        ---
        %tag
          Some non-inline text
        - 'some code'
          ---
      HAML

      it 'is not greedy' do
        expect(parser.contents).to eq(normalize_indent(<<-CONTENT))
          %tag
            Some non-inline text
          - 'some code'
            ---
        CONTENT
      end
    end
  end

  context 'when skip_frontmatter is false' do
    let(:parser) { HamlLint::Parser.new(haml, 'skip_frontmatter' => false) }
    let(:haml) { normalize_indent(<<-HAML) }
      ---
      :key: value
      ---
      %tag
        Some non-inline text
      - 'some code'
    HAML

    it 'raises HAML error' do
      expect { parser }.to raise_error Haml::Error
    end
  end
end
