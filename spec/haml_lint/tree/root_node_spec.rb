# frozen_string_literal: false

RSpec.describe HamlLint::Tree::RootNode do
  describe '#node_for_line' do
    let(:document) { HamlLint::Document.new(haml, config: {}) }
    let(:root_node) { document.tree }

    context 'when it cannot find node' do
      let(:haml) { '' }

      subject { root_node.node_for_line('no such node') }

      it { is_expected.to be_a(HamlLint::Tree::NullNode) }
    end
  end
end
