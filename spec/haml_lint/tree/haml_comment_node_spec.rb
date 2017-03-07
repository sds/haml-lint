require 'spec_helper'

describe HamlLint::Tree::HamlCommentNode do
  let(:options) do
    {
      config: HamlLint::ConfigurationLoader.default_configuration,
    }
  end

  let(:document) { HamlLint::Document.new(normalize_indent(haml), options) }
  let(:node) { document.tree.find { |node| node.type == :haml_comment } }

  subject { node }

  describe '#directives' do
    subject { super().directives }

    context 'when there are no directives' do
      let(:haml) { '-# A comment' }

      it { should == [] }
    end

    context 'when there are directives in the node' do
      let(:haml) { '-# haml-lint:disable AltText' }

      it { should eq([HamlLint::Directive.new(haml, 1, 'disable', %w[AltText])]) }

      context 'with bad formatting' do
        let(:haml) { '-#haml-lint  :disable AltText' }

        it { should eq([HamlLint::Directive.new(haml, 1, 'disable', %w[AltText])]) }
      end
    end

    context 'when there are directives from a parent' do
      let(:haml) { lines.join("\n") }
      let(:lines) do
        [
          '-# haml-lint:disable AltText',
          '-# haml-lint:enable LineLength'
        ]
      end
      let(:node) { document.tree.select { |node| node.type == :haml_comment }.last }

      let(:expectation) do
        [
          HamlLint::Directive.new(lines.first, 1, 'disable', %w[AltText]),
          HamlLint::Directive.new(lines.last, 2, 'enable', %w[LineLength])
        ]
      end

      it { should eq(expectation) }
    end

    context 'when there are directives outside the scope of a node' do
      let(:haml) { lines.join("\n") }
      let(:lines) do
        [
          '-# haml-lint:disable AltText',
          '%div',
          '  #haml-lint:disable AlignmentTabs',
          '-# haml-lint:enable LineLength'
        ]
      end
      let(:node) { document.tree.select { |node| node.type == :haml_comment }.last }

      let(:out_of_scope) do
        HamlLint::Directive.new(lines[2], 3, 'disable', %w[AlignmentTabs])
      end

      it { should_not include(out_of_scope) }
    end
  end

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
