require 'spec_helper'

describe HamlLint::Tree::TagNode do
  let(:parser) { HamlLint::Parser.new(normalize_indent(haml)) }
  let(:tag_node) { parser.tree.find { |node| node.type == :tag && node.tag_name == tag_name } }
  let(:tag_name) { 'my_tag' }

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

      it { should == { html:  "(three=3\n                            four=4)" } }
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
          hash: "{ one: 1,\n                             two: 2 }",
          html:  '(three=3)',
          object_ref: '[my_object]'
        }
      end
    end
  end
end
