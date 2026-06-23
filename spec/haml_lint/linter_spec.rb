# frozen_string_literal: false

describe HamlLint::Linter do
  let(:linter_class) do
    Class.new(described_class) do
      def visit_root(node)
        record_lint(node, 'A lint!')
      end
    end
  end

  let(:config) { {} }
  let(:linter) { linter_class.new(config) }

  describe '#run' do
    let(:options) do
      {
        config: HamlLint::ConfigurationLoader.default_configuration,
        file: 'file.haml',
      }
    end

    let(:document) { HamlLint::Document.new('%p Hello world', options) }
    subject { linter.run(document) }

    it 'returns the reported lints' do
      subject.length.should == 1
    end

    context 'when a linter calls parse_ruby' do
      let(:linter_class) do
        Class.new(described_class) do
          attr_reader :parsed_ruby

          def visit_root(_node)
            @parsed_ruby = parse_ruby('puts')
          end
        end
      end

      it 'parses the ruby' do
        subject
        linter.parsed_ruby.type.should == :send
      end
    end
  end

  describe 'autocorrect safety gate' do
    let(:options) do
      {
        config: HamlLint::ConfigurationLoader.default_configuration,
        file: 'file.haml',
      }
    end

    # A linter whose only job is to rewrite the document to a marker string when
    # its safety gate permits, so we can observe whether a correction was applied.
    def gated_linter_class(safe:)
      Class.new(HamlLint::Linter) do
        supports_autocorrect(true)
        autocorrect_safe(safe)

        def visit_root(_root)
          record_lint(1, 'Needs correcting', corrected: autocorrect?)
          apply_autocorrect('%p corrected')
        end
      end
    end

    let(:document) { HamlLint::Document.new('%p original', options) }

    def run_linter(safe:, autocorrect:)
      linter = gated_linter_class(safe: safe).new(config)
      linter.run(document, autocorrect: autocorrect)
      linter
    end

    context 'a safe linter' do
      it 'applies the correction under :safe' do
        run_linter(safe: true, autocorrect: :safe)
        document.source.should == '%p corrected'
        document.source_was_changed.should == true
      end

      it 'applies the correction under :all' do
        run_linter(safe: true, autocorrect: :all)
        document.source.should == '%p corrected'
        document.source_was_changed.should == true
      end
    end

    context 'an unsafe linter' do
      it 'does not change the source under :safe' do
        linter = run_linter(safe: false, autocorrect: :safe)
        document.source.should == '%p original'
        document.source_was_changed.should == false
        linter.lints.first.corrected.should == false
      end

      it 'applies the correction under :all' do
        run_linter(safe: false, autocorrect: :all)
        document.source.should == '%p corrected'
        document.source_was_changed.should == true
      end
    end

    context 'with no autocorrect mode' do
      it 'never changes the source' do
        run_linter(safe: true, autocorrect: nil)
        document.source.should == '%p original'
        document.source_was_changed.should == false
      end
    end
  end

  describe '.autocorrect_priority' do
    it 'defaults to 0 when never declared' do
      linter_class = Class.new(HamlLint::Linter)
      linter_class.autocorrect_priority.should == 0
    end

    it 'returns the value declared in the linter body' do
      linter_class = Class.new(HamlLint::Linter) do
        autocorrect_priority(5)
      end
      linter_class.autocorrect_priority.should == 5
    end

    it 'declares FinalNewline to run after the default linters' do
      HamlLint::Linter::FinalNewline.autocorrect_priority.should be > 0
    end
  end

  describe '#name' do
    subject { linter.name }

    before do
      linter.class.stub(:name).and_return('HamlLint::Linter::SomeLinterName')
    end

    it { should == 'SomeLinterName' }
  end

  # Source from https://apidock.com/rails/Class/descendants
  linter_classes = []
  ObjectSpace.each_object(HamlLint::Linter.singleton_class) do |k|
    next if k.singleton_class?
    linter_classes.unshift k unless k == self
  end
  linter_classes.each do |linter_class|
    describe "subclass #{linter_class.name}" do
      # Needed for parallel mode, because lints are dumped and they refer to the linter
      it 'instances can be Marshal.dump' do
        document = HamlLint::Document.new('something', config: HamlLint::ConfigurationLoader.default_configuration)
        expect do
          linter = linter_class.new(config)
          linter.run(document)

          Marshal.dump(linter)
        end.not_to raise_error
      end
    end
  end
end
