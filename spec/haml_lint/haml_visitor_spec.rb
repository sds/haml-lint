# frozen_string_literal: true

describe HamlLint::HamlVisitor do
  describe '#visit' do
    let(:options) do
      {
        config: HamlLint::ConfigurationLoader.default_configuration,
      }
    end

    let(:document) { HamlLint::Document.new(normalize_indent(haml), options) }

    before { visitor.visit(document.tree) }

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
          @node_order << node.tag_name
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
          @node_order << node.tag_name
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
          @node_order << node.tag_name
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
          @node_order << node.script.strip
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
          @node_order << node.script.strip
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

    context 'when visitor defines a visit_haml_comment method' do
      class HamlCommentVisitor < TrackingVisitor
        def visit_haml_comment(node)
          @node_order << node.text
        end
      end

      let(:visitor) { HamlCommentVisitor.new }

      context 'and the HAML document is empty' do
        let(:haml) { '' }

        it 'visits no nodes' do
          visitor.node_order.should == []
        end
      end

      context 'and there are comments in the document' do
        let(:haml) { <<-HAML }
          -# A comment
          %tag
          -# Another comment
        HAML

        it 'visits each comment' do
          visitor.node_order.should == [' A comment', ' Another comment']
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

    context 'when a node disables the visitor' do
      class DisabledVisitor < TrackingVisitor
        def visit_child(node)
          @node_order << node.type
        end

        def visit_root(node)
          @node_order << node.type
        end
      end

      let(:child_node) { double('child', children: [], disabled?: false, type: :child) }
      let(:document) { double('document', tree: node) }
      let(:node) { double('node', children: [child_node], disabled?: true, type: :root) }
      let(:visitor) { DisabledVisitor.new }

      it 'does not visit the node' do
        visitor.node_order.should_not include(:root)
      end

      it 'visits the child node' do
        visitor.node_order.should include(:child)
      end
    end
  end
end
