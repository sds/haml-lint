
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

  describe '#name' do
    subject { linter.name }

    before do
      linter.class.stub(:name).and_return('HamlLint::Linter::SomeLinterName')
    end

    it { should == 'SomeLinterName' }
  end
end
