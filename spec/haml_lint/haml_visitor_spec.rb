require 'spec_helper'

describe HamlLint::HamlVisitor do
  describe '#visit' do
    let(:parser) { HamlLint::Parser.new(normalize_indent(haml)) }

    before { visitor.visit(parser.tree) }

    class TrackingVisitor
      include HamlLint::HamlVisitor

      attr_reader :node_order

      def initialize
        @node_order = []
      end
    end

    context 'when visitor defines a visit_* method with no yield statement' do
      class NoYieldVisitor < TrackingVisitor
        def visit_tag(node)
          @node_order << node.value[:name]
        end
      end

      let(:visitor) { NoYieldVisitor.new }

      let(:haml) { <<-HAML }
        %tag
          %child
            %child2
      HAML

      it 'visits all nodes' do
        visitor.node_order.should == %w[tag child child2]
      end
    end

    context 'when visitor defines a visit_* method which yields :none' do
      class YieldFalseVisitor < TrackingVisitor
        def visit_tag(node)
          @node_order << node.value[:name]
          yield :none
        end
      end

      let(:visitor) { YieldFalseVisitor.new }

      let(:haml) { <<-HAML }
        %tag
          %childA
            %childB
      HAML

      it 'visits the top-most node' do
        visitor.node_order.should include 'tag'
      end

      it 'does not visit the children of top-most nodes' do
        visitor.node_order.should_not include 'childA'
        visitor.node_order.should_not include 'childB'
      end
    end

    context 'when visitor defines a visit_* method which yields :children' do
      class YieldChildrenVisitor < TrackingVisitor
        def visit_tag(node)
          yield :children
          @node_order << node.value[:name]
        end
      end

      let(:visitor) { YieldChildrenVisitor.new }

      let(:haml) { <<-HAML }
        %tag
          %childA
            %childC
          %childB
      HAML

      it 'visits all nodes' do
        visitor.node_order.should include 'tag', 'childA', 'childB', 'childC'
      end

      it 'visits based on the location of the yield statement' do
        visitor.node_order.should == %w[childC childA childB tag]
      end
    end

    context 'when visitor defines a visit_script method' do
      class ScriptVisitor < TrackingVisitor
        def visit_script(node)
          @node_order << node.value[:text].strip
        end
      end

      let(:visitor) { ScriptVisitor.new }

      context 'and there are no script nodes' do
        let(:haml) { <<-HAML }
          %tag
          - silent_script
        HAML

        it 'visits no script nodes' do
          visitor.node_order.should be_empty
        end
      end

      context 'and there are script nodes' do
        let(:haml) { <<-HAML }
          = scriptA
          = scriptB
          %tag
            = scriptC
        HAML

        it 'visits all script nodes' do
          visitor.node_order.should == %w[scriptA scriptB scriptC]
        end
      end
    end

    context 'when visitor defines a visit_silent_script method' do
      class SilentScriptVisitor < TrackingVisitor
        def visit_silent_script(node)
          @node_order << node.value[:text].strip
        end
      end

      let(:visitor) { SilentScriptVisitor.new }

      context 'and there are no silent script nodes' do
        let(:haml) { <<-HAML }
          %tag
          = script
        HAML

        it 'visits no silent script nodes' do
          visitor.node_order.should be_empty
        end
      end

      context 'and there are silent script nodes' do
        let(:haml) { <<-HAML }
          - scriptA
          - scriptB
          %tag
            - scriptC
        HAML

        it 'visits all silent script nodes' do
          visitor.node_order.should == %w[scriptA scriptB scriptC]
        end
      end
    end

    context 'when visitor defines a visit_root method' do
      class RootVisitor < TrackingVisitor
        def visit_root(node)
          @node_order << node.type
        end
      end

      let(:visitor) { RootVisitor.new }

      context 'and the HAML document is empty' do
        let(:haml) { '' }

        it 'visits the root node once' do
          visitor.node_order.should == [:root]
        end
      end

      context 'and there are various nodes in the HAML document' do
        let(:haml) { <<-HAML }
          %tag
          = script do
            %child
          - silent_script
        HAML

        it 'visits the root node once' do
          visitor.node_order.should == [:root]
        end
      end
    end
  end
end
