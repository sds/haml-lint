require 'spec_helper'

describe HamlLint::Tree::Node do
  let(:parser) { HamlLint::Parser.new(normalize_indent(haml)) }

  describe '#find' do
    subject { parser.tree.find(&matcher) }
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

  describe '#successor' do
    subject { parser.tree.find { |node| node.type == :haml_comment }.successor }

    context 'when finding the successor of the root node' do
      subject { parser.tree.successor }
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
