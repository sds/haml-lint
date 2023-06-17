# frozen_string_literal: false

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

        it 'reports line numbers as if frontmatter was not removed' do
          expect(subject.tree.children.first.line).to eq(4)
        end
      end

      context 'and the source does not contain frontmatter' do
        it 'leaves the source untouched' do
          subject.source == source
        end
      end
    end

    context 'when given an invalid HAML document' do
      let(:source) { normalize_indent(<<-HAML) }
        %body
          %div
              %p
      HAML

      it 'raises an error' do
        expect { subject }.to raise_error HamlLint::Exceptions::ParseError
      end

      it 'includes the line number in the exception' do
        subject
      rescue HamlLint::Exceptions::ParseError => e
        e.line.should == 2
      end
    end

    context 'when source is valid UTF-8 but was interpeted as US-ASCII' do
      let(:source) { '%p Test àéùö'.force_encoding('US-ASCII') }

      it 'interprets it as UTF-8' do
        expect { subject }.to_not raise_error
      end
    end

    context 'when given a file with different line endings' do
      context 'that are just carriage returns' do
        let(:source) { "%div\r  %p\r    Hello, world" }

        it 'interprets the line endings as newlines, like Haml' do
          expect { subject }.to_not raise_error
        end
      end

      context 'that are Windows-style CRLF' do
        let(:source) { "%div\r\n  %p\r\n    Hello, world" }

        it 'interprets the line endings as newlines, like Haml' do
          expect { subject }.to_not raise_error
        end
      end
    end
  end

  describe '#change_source' do
    let(:source) { <<~HAML }
      %head
        %title My title
    HAML

    let(:options) { { config: config } }

    subject { described_class.new(source, options) }

    it 'sets source_was_changed to true when source is different' do
      subject.change_source(<<~HAML)
        %tag
          This all is different
      HAML
      subject.source_was_changed.should be true
    end

    it "doesn't set source_was_changed to true when source is different" do
      subject.change_source(source)
      subject.source_was_changed.should be false
    end

    context 'when skip_frontmatter is specified in config' do
      before do
        config.stub(:[]).with('skip_frontmatter').and_return(true)
      end

      context 'and there is Front Matter' do
        let(:source) { <<~HAML }
          ---
          foo: bar
          ---
          %head
            %title My title
        HAML

        it "raises if the new source doesn't have enough leading newlines at the start" do
          expect {
            subject.change_source(<<~HAML)

            %tag
              This all is different
            HAML
          }.to raise_error(HamlLint::Exceptions::IncompatibleNewSource)
        end

        it "works if the new source has enough leading newlines at the start" do
          subject.change_source(<<~HAML)



            %tag
              This all is different
          HAML

          subject.source_was_changed.should be true
        end
      end

      context 'and there is no Front Matter' do
        it "works if without any leading newlines" do
          subject.change_source(<<~HAML)
            %tag
              This all is different
          HAML

          subject.source_was_changed.should be true
        end
      end
    end
  end

  describe '#write_to_disk!' do
    let(:source) { <<~HAML }
      %head
        %title My title
    HAML

    let(:tempfile) { Tempfile.new }

    let(:options) { { config: config, file: tempfile.path } }

    subject { described_class.new(source, options) }

    context 'when skip_frontmatter is specified in config' do
      before do
        config.stub(:[]).with('skip_frontmatter').and_return(true)
      end

      context 'and there is Front Matter' do
        let(:source) { <<~HAML }
          ---
          foo: bar
          ---
          %head
            %title My title
        HAML

        it "keeps the Front Matter when changing" do
          new_source = <<~HAML



            %tag
              This all is different
          HAML

          final_source = <<~HAML
            ---
            foo: bar
            ---
            %tag
              This all is different
          HAML
          subject.change_source(new_source)
          subject.write_to_disk!

          expect(File.read(tempfile.path)).to eq(final_source)
        end
      end

      context 'and there is no Front Matter' do

      end
    end
  end
end
