# frozen_string_literal: true

describe HamlLint::Tree::TagNode do
  let(:options) do
    {
      config: HamlLint::ConfigurationLoader.default_configuration,
    }
  end

  let(:document) { HamlLint::Document.new(normalize_indent(haml), options) }
  let(:tag_node) { document.tree.find { |node| node.type == :tag && node.tag_name == tag_name } }
  let(:tag_name) { 'my_tag' }

  describe '#has_hash_attribute?' do
    subject { tag_node.has_hash_attribute?(:one) }

    context 'when the node has the attribute' do
      let(:haml) { '%my_tag{ one: 1 }' }

      it { should == true }
    end

    context 'when the node does not have the attribute' do
      let(:haml) { '%my_tag{ two: 2 }' }

      it { should == false }
    end

    context 'when the node has multiple hash attributes' do
      let(:haml) { '%my_tag{ one: 1, two: 2 }' }

      it { should == true }
    end

    context 'when the node has no hash attributes' do
      let(:haml) { '%my_tag' }

      it { should == false }
    end

    context 'when the node has attributes from a variable' do
      let(:haml) { '%my_tag{some_variable}' }

      it { should == false }
    end
  end

  describe '#dynamic_attributes_source' do
    subject { tag_node.dynamic_attributes_source }

    context 'with no dynamic attributes' do
      let(:haml) { '%my_tag.class_one.class_two#with_an_id' }

      it { should == {} }
    end

    context 'with html attributes on one line' do
      let(:haml) { '%my_tag.class_one.class_two#with_an_id(three=3 four=4)' }

      it { should == { html: '(three=3 four=4)' } }
    end

    context 'with multi-line html attributes' do
      let(:haml) { <<-HAML }
        %my_tag.class_one.class_two(three=3
                                    four=4)
      HAML

      it { should == { html: "(three=3\n                            four=4)" } }
    end

    context 'with an object reference' do
      let(:haml) { '%my_tag.class_one.class_two[my_object]' }

      it { should == { object_ref: '[my_object]' } }
    end

    context 'with hash attributes on one line' do
      let(:haml) { '%my_tag.class_one.class_two#with_an_id{ one: 1, two: 2 }' }

      it { should == { hash: '{ one: 1, two: 2 }' } }
    end

    context 'with hash attributes on an implicit div' do
      let(:tag_name) { 'div' }

      context 'with a class' do
        context 'at the beginning of a line' do
          let(:haml) { '.class_one.class_two#with_an_id{ one: 1, two: 2 }' }

          it { should == { hash: '{ one: 1, two: 2 }' } }
        end

        context 'with leading whitespace' do
          let(:haml) { '  .class_one.class_two#with_an_id{ one: 1, two: 2 }' }

          it { should == { hash: '{ one: 1, two: 2 }' } }
        end
      end

      context 'with only an id' do
        context 'at the beginning of a line' do
          let(:haml) { '#with_an_id{ one: 1, two: 2 }' }

          it { should == { hash: '{ one: 1, two: 2 }' } }
        end

        context 'with leading whitespace' do
          let(:haml) { '  #with_an_id{ one: 1, two: 2 }' }

          it { should == { hash: '{ one: 1, two: 2 }' } }
        end
      end
    end

    context 'with multi-line hash attributes' do
      let(:haml) { <<-HAML }
        %my_tag.class_one.class_two#with_an_id{ one: 1,
                                                two: 2 }
      HAML

      it { should == { hash: "{ one: 1,\n                                        two: 2 }" } }
    end
  end

  describe '#attributes_source' do
    subject { tag_node.attributes_source }

    context 'with multi-line hash attributes with contextual noise' do
      let(:haml) { <<-HAML }
        %first_tag { zero: 0 }
        %my_tag.class_one.class_two{ one: 1,
                                     two: 2 }(three=3)[my_object]
          Some Nested Text
        %other_tag.class_three#id_four{ five: 5 }
      HAML

      it do
        should == {
          static: '.class_one.class_two',
          hash: "{ one: 1,\n                             two: 2 }",
          html: '(three=3)',
          object_ref: '[my_object]'
        }
      end
    end
  end

  describe '#html_attributes_source' do
    subject { tag_node.html_attributes_source }

    context 'when no HTML attributes are present' do
      let(:haml) { '%my_tag' }

      it { should be_nil }
    end

    context 'when HTML attributes are present but empty' do
      let(:haml) { '%my_tag()' }

      it { should == '' }
    end

    context 'when HTML attributes are present' do
      let(:haml) { '%my_tag(one=1 two=2 three=3)' }

      it { should == 'one=1 two=2 three=3' }
    end
  end

  describe '#object_reference_source' do
    subject { tag_node.object_reference_source }

    context 'when no object references are present' do
      let(:haml) { '%my_tag' }

      it { should be_nil }
    end

    context 'when object reference is present but empty' do
      let(:haml) { '%my_tag[]' }

      it { should == '' }
    end

    context 'when object reference is present' do
      let(:haml) { '%my_tag[@some_object]' }

      it { should == '@some_object' }
    end
  end

  describe '#static_attributes_source' do
    subject { tag_node.static_attributes_source }

    context 'with no dynamic attributes' do
      let(:haml) { '%my_tag.class_one.class_two#with_an_id' }

      it { should == '.class_one.class_two#with_an_id' }
    end

    context 'with assorted dynamic attributes' do
      let(:haml) { '%my_tag.class_one.class_two#with_an_id{ one: 1, two: 2 }(three=3)[my_object]' }

      it { should == '.class_one.class_two#with_an_id' }
    end

    context 'with an implicit div' do
      let(:tag_name) { 'div' }

      context 'with a class' do
        let(:haml) { '.class_one.class_two#with_an_id' }

        it { should == '.class_one.class_two#with_an_id' }
      end

      context 'without a class, with an id' do
        let(:haml) { '#with_an_id' }

        it { should == '#with_an_id' }
      end
    end
  end

  describe '#remove_inner_whitespace?' do
    subject { tag_node.remove_inner_whitespace? }

    context 'when < symbol not present' do
      let(:haml) { '%my_tag' }

      it { should == false }
    end

    context 'when < symbol present' do
      let(:haml) { '%my_tag<' }

      it { should == true }
    end

    context 'when both <> symbols present' do
      let(:haml) { '%my_tag<>' }

      it { should == true }
    end
  end

  describe '#remove_outer_whitespace?' do
    subject { tag_node.remove_outer_whitespace? }

    context 'when > symbol not present' do
      let(:haml) { '%my_tag' }

      it { should == false }
    end

    context 'when > symbol present' do
      let(:haml) { '%my_tag>' }

      it { should == true }
    end

    context 'when both <> symbols present' do
      let(:haml) { '%my_tag<>' }

      it { should == true }
    end
  end
end
