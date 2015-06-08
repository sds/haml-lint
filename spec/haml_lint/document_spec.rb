require 'spec_helper'

describe HamlLint::Document do
  let(:config) { double }

  before do
    config.stub(:[]).with('skip_frontmatter').and_return(false)
  end

  describe '#initialize' do
    let(:source) { normalize_indent(<<-HAML) }
      %head
        %title My title
      %body
        %p My paragraph
    HAML

    let(:options) { { config: config } }

    subject { described_class.new(source, options) }

    it 'stores a tree representing the parsed document' do
      subject.tree.should be_a HamlLint::Tree::Node
    end

    it 'stores the source code' do
      subject.source == source
    end

    it 'stores the individual lines of source code' do
      subject.source_lines == source.split("\n")
    end

    context 'when file is explicitly specified' do
      let(:options) { super().merge(file: 'my_file.haml') }

      it 'sets the file name' do
        subject.file == 'my_file.haml'
      end
    end

    context 'when file is not specified' do
      it 'sets a dummy file name' do
        subject.file == HamlLint::Document::STRING_SOURCE
      end
    end

    context 'when skip_frontmatter is specified in config' do
      before do
        config.stub(:[]).with('skip_frontmatter').and_return(true)
      end

      context 'and the source contains frontmatter' do
        let(:source) { "---\nsome frontmatter\n---\n#{super()}" }

        it 'removes the frontmatter' do
          subject.source.should_not include '---'
          subject.source.should include '%head'
        end
      end

      context 'and the source does not contain frontmatter' do
        it 'leaves the source untouched' do
          subject.source == source
        end
      end
    end
  end
end
