require 'spec_helper'

describe HamlLint::Tree::HamlCommentNode do
  let(:parser) { HamlLint::Parser.new(normalize_indent(haml)) }
  subject { parser.tree.find { |node| node.type == :haml_comment } }

  describe '#text' do
    subject { super().text }

    context 'when comment is a single line' do
      let(:haml) { '-# A comment' }

      it { should == ' A comment' }

      context 'and indented' do
        let(:haml) { <<-HAML }
          %tag
            -# An indented comment
        HAML

        it { should == ' An indented comment' }
      end
    end

    context 'when comment spreads over multiple lines' do
      let(:haml) { <<-HAML }
        -#
          Line one
          Line two
          Line three
      HAML

      it { should == "\nLine one\nLine two\nLine three" }

      context 'and is indented' do
        let(:haml) { <<-HAML }
          %tag
            -#
              Line one
              Line two
              Line three
        HAML

        it { should == "\nLine one\nLine two\nLine three" }
      end

      context 'and is immediately followed by a node' do
        let(:haml) { <<-HAML }
          -#
            Line one
            Line two
            Line three
          %tag
        HAML

        it { should == "\nLine one\nLine two\nLine three" }
      end

      context 'and is followed by a blank line and a node' do
        let(:haml) { <<-HAML }
          -#
            Line one
            Line two
            Line three

          %tag
        HAML

        it { should == "\nLine one\nLine two\nLine three" }
      end
    end

    context 'when comment spreads over multiple lines with gaps' do
      let(:haml) { <<-HAML }
        -#
          Line one

          Line two

          Line three
      HAML

      it { should == "\nLine one\n\nLine two\n\nLine three" }

      context 'and is immediately followed by a node' do
        let(:haml) { <<-HAML }
          -#
            Line one

            Line two

            Line three
          %tag
        HAML

        it { should == "\nLine one\n\nLine two\n\nLine three" }
      end

      context 'and is followed by a blank line and a node' do
        let(:haml) { <<-HAML }
          -#
            Line one

            Line two

            Line three

          %tag
        HAML

        it { should == "\nLine one\n\nLine two\n\nLine three" }
      end
    end
  end
end
