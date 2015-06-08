require 'spec_helper'

describe HamlLint::Tree::Node do
  let(:options) do
    {
      config: HamlLint::ConfigurationLoader.default_configuration,
    }
  end

  let(:document) { HamlLint::Document.new(normalize_indent(haml), options) }

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

        it { should == "%tag{ a: 1,\n      b: 2,\n      c: 3 }" }
      end
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
