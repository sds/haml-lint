# frozen_string_literal: true

describe HamlLint::Tree::Node do
  let(:options) do
    {
      config: HamlLint::ConfigurationLoader.default_configuration,
    }
  end

  let(:document) { HamlLint::Document.new(normalize_indent(haml), options) }

  describe '#directives' do
    subject do
      document.tree.find { |node| node.type == :tag && node.tag_id == 'my-node' }.directives
    end

    let(:haml) { <<-HAML }
      -# haml-lint:disable AltText
      %one
      %two
        %three
          #my-node
        %five
        - # haml-lint:enable AltText
      %five
    HAML

    it 'inherits from its ancestors and ignore the out-of-scope directives' do
      expected = HamlLint::Directive.new('-# haml-lint:disable AltText', 1, 'disable', %w[AltText])

      subject.should == [expected]
    end
  end

  describe '#find' do
    subject { document.tree.find(&matcher) }
    let(:matcher) { ->(node) { node.type == :haml_comment } }

    context 'when there are no nodes' do
      let(:haml) { '' }

      it { should be_nil }
    end

    context 'when there are no matching nodes' do
      let(:haml) { <<-HAML }
        %one
        %two
          %three
            %four
          %five
        %five
      HAML

      it { should be_nil }
    end

    context 'when there are multiple matching nodes' do
      let(:haml) { <<-HAML }
        %one
        %two
          %three
            %four
            -# First match
          %five
          - # Second match
        %five
      HAML

      its(:text) { should == ' First match' }
    end
  end

  describe '#source_code' do
    subject { document.tree.find { |node| node.type == :tag }.source_code }

    context 'when node in the middle of the document' do
      let(:haml) { <<-HAML }
        - if some_conditional
          %tag{ a: 1 }
        - else
          = some_script
      HAML

      it { should == '  %tag{ a: 1 }' }

      context 'and it spans multiple lines' do
        let(:haml) { <<-HAML }
          - if some_conditional
            %tag{ a: 1,
                  b: 2,
                  c: 3 }
          - else
            = some_script
        HAML

        it { should == "  %tag{ a: 1,\n        b: 2,\n        c: 3 }" }
      end

      context 'and it has children' do
        let(:haml) { <<-HAML }
          - if some_conditional
            %tag{ a: 1,
                  b: 2,
                  c: 3 }
              = some_script
          - else
            = some_script
        HAML

        it { should == "  %tag{ a: 1,\n        b: 2,\n        c: 3 }" }
      end

      context 'and it spans multiple lines with blank lines' do
        let(:haml) { <<-HAML }
          - if some_conditional
            %tag{ a: 1,
                  b: 2,
                  c: 3 }


          - else
            = some_script
        HAML

        it { should == "  %tag{ a: 1,\n        b: 2,\n        c: 3 }\n" }
      end
    end

    context 'when node is at the end of the document' do
      let(:haml) { '%tag' }

      it { should == '%tag' }

      context 'and it spans multiple lines' do
        let(:haml) { <<-HAML }
          %tag{ a: 1,
                b: 2,
                c: 3 }
        HAML

        it { should == "%tag{ a: 1,\n      b: 2,\n      c: 3 }\n" }

        context 'without a final newline' do
          let(:haml) { super().rstrip }

          it { should == "%tag{ a: 1,\n      b: 2,\n      c: 3 }" }
        end
      end
    end
  end

  describe '#inspect' do
    let(:haml) { '%span' }
    subject { document.tree.inspect }

    it { should == '#<HamlLint::Tree::RootNode>' }
  end

  describe '#line_numbers' do
    subject { document.tree.children.first.line_numbers }

    context 'for a node with a body' do
      let(:haml) do
        <<-HAML
          %p
            This is the body of the paragraph tag
            and it goes over multiple lines.
        HAML
      end

      it { should == (1..1) }

      context 'with a successor' do
        let(:haml) do
          <<-HAML
            %p
              This is the body of the paragraph tag
              and it goes over multiple lines.
            %p This is a successor
          HAML
        end

        it { should == (1..1) }
      end
    end

    context 'for a multiline node' do
      let(:haml) do
        <<-HAML
          %p{ |
            'data-test' => 'This is a multiline node' } |
        HAML
      end

      it { should == (1..2) }

      context 'with many trailing lines' do
        let(:haml) do
          <<-HAML
          %p{ |
            'data-test' => 'This is a multiline node' } |


          HAML
        end

        it { should == (1..2) }
      end

      context 'with a successor' do
        let(:haml) do
          <<-HAML
            %p{ |
              'data-test' => 'This is a multiline node' } |
            %p This is a successor
          HAML
        end

        it { should == (1..2) }
      end
    end

    context 'for a single-line node without a successor' do
      let(:haml) do
        <<-HAML
          %p This is a single-line node
        HAML
      end

      it { should == (1..1) }
    end

    context 'for a node with a successor and no body' do
      let(:haml) { '%p' }

      it { should == (1..1) }
    end
  end

  describe '#predecessor' do
    subject { document.tree.find { |node| node.type == :haml_comment }.predecessor }

    context 'when finding the predecessor of the root node' do
      subject { document.tree.predecessor }
      let(:haml) { '-# Dummy node' }

      it { should be_nil }
    end

    context 'when there are no prior nodes' do
      let(:haml) { '-# Just a lonely node' }

      it { should eq(document.tree) }
    end

    context 'when there are prior nodes' do
      let(:haml) { <<-HAML }
        -#Predecessor
        -# A regular node
        -#NotAPredecessor
      HAML

      subject do
        document.tree.find do |node|
          node.type == :haml_comment && node.text == ' A regular node'
        end.predecessor
      end

      its(:text) { should == 'Predecessor' }
    end

    context 'when there are prior nodes for a deeply nested node' do
      let(:haml) { <<-HAML }
        %one
          %two
            %three
              -# Deeply nested node
      HAML

      subject do
        document.tree.find do |node|
          node.type == :haml_comment && node.text == ' Deeply nested node'
        end.predecessor
      end

      its(:tag_name) { should eq('three') }
    end
  end

  describe '#successor' do
    subject { document.tree.find { |node| node.type == :haml_comment }.successor }

    context 'when finding the successor of the root node' do
      subject { document.tree.successor }
      let(:haml) { '-# Dummy node' }

      it { should be_nil }
    end

    context 'when there are no subsequent nodes' do
      let(:haml) { '-# Just a lonely node' }

      it { should be_nil }
    end

    context 'when there are subsequent nodes' do
      let(:haml) { <<-HAML }
        -# A regular node
        -#Successor
        -#NotASuccessor
      HAML

      its(:text) { should == 'Successor' }
    end

    context 'when there are no subsequent nodes for a deeply nested node' do
      let(:haml) { <<-HAML }
        %one
          %two
            %three
              -# Deeply nested node
      HAML

      it { should be_nil }
    end

    context 'when there are subsequent nodes for a deeply nested node' do
      context 'at the same level' do
        let(:haml) { <<-HAML }
          %one
            %two
              %three
                -# Deeply nested node
                -#Successor
              -#NotASuccessor
        HAML

        its(:text) { should == 'Successor' }
      end

      context 'at one level up the ancestral chain' do
        let(:haml) { <<-HAML }
          %one
            %two
              %three
                -# Deeply nested node
              -#Successor
            -#NotASuccessor
        HAML

        its(:text) { should == 'Successor' }
      end

      context 'at two levels up the ancestral chain' do
        let(:haml) { <<-HAML }
          %one
            %two
              %three
                -# Deeply nested node
            -#Successor
            -#NotASuccessor
        HAML

        its(:text) { should == 'Successor' }
      end
    end
  end
end
