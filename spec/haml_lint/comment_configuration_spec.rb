RSpec.describe HamlLint::CommentConfiguration do
  subject(:config) { described_class.new(node) }

  context 'for a node with no directives' do
    let(:node) { double('node', directives: []) }

    describe '#disabled?' do
      subject { config.disabled?('all') }

      it { is_expected.to eq(false) }
    end
  end

  context 'for a node with directives' do
    let(:config) { double('config') }
    let(:document) { HamlLint::Document.new(source, options) }
    let(:options) { { config: { 'skip_frontmatter' => true } } }
    let(:source) do
      [
        '-#',
        '  haml-lint:disable AltText',
        '  haml-lint:disable LineLength',
        '%img{ src: "test-no-lint.png" }',
        '%div',
        '  %img{ src: "test-no-lint-2.png" }',
        '-# haml-lint:enable AltText',
        '%img{ src: "test-lint.png" }',
        '%div',
        '  -# haml-lint:disable AltText',
        '  %img{src: "test-no-lint-3.png"}',
        '%img{src: "test-lint-2.png"}'
      ].join("\n")
    end

    describe '#disabled?' do
      subject { document.tree.select { |node| node.disabled?(linter) }.map(&:line) }

      context 'for the AltText linter' do
        let(:linter) { HamlLint::Linter::AltText.new(config) }

        it 'is disabled for the image tags for test-no-lint sources' do
          test_no_lint = document.tree.select do |node|
            node.type == :tag && node.source_code =~ /test-no-lint/
          end

          expect(test_no_lint.all? { |node| node.disabled?(linter) }).to eq(true)
        end

        it 'is not disabled for the image tags for test-lint sources' do
          test_lint = document.tree.select do |node|
            node.type == :tag && node.source_code =~ /test-lint/
          end

          expect(test_lint.none? { |node| node.disabled?(linter) }).to eq(true)
        end
      end

      context 'for the LineLength linter' do
        let(:linter) { HamlLint::Linter::LineLength.new(config) }

        it 'is disabled for every node except the root in the tree' do
          root_disabled = document.tree.disabled?(linter)
          all_others_disabled = document.tree.children.all? { |node| node.disabled?(linter) }

          expect(root_disabled).to eq(false)
          expect(all_others_disabled).to eq(true)
        end
      end
    end
  end

  context 'for a node that has an "all" directive' do
    let(:config) { double('config') }
    let(:document) { HamlLint::Document.new(source, options) }
    let(:options) { { config: { 'skip_frontmatter' => true } } }

    context 'that is being overridden' do
      let(:source) do
        [
          '-# haml-lint:disable all',
          '%img{ src: "test-no-lint.png" }',
          '%div',
          '  %img{ src: "test-no-lint-2.png" }',
          '-# haml-lint:enable AltText',
          '%img{ src: "test-lint.png" }',
          '%div',
          '  -# haml-lint:disable AltText',
          '  %img{src: "test-no-lint-3.png"}',
          '%img{src: "test-lint-2.png"}'
        ].join("\n")
      end

      describe '#disabled?' do
        subject { document.tree.select { |node| node.disabled?(linter) }.map(&:line) }

        context 'for the AltText linter' do
          let(:linter) { HamlLint::Linter::AltText.new(config) }

          it 'is disabled for the image tags for test-no-lint sources' do
            test_no_lint = document.tree.select do |node|
              node.type == :tag && node.source_code =~ /test-no-lint/
            end

            expect(test_no_lint.all? { |node| node.disabled?(linter) }).to eq(true)
          end

          it 'is not disabled for the image tags for test-lint sources' do
            test_lint = document.tree.select do |node|
              node.type == :tag && node.source_code =~ /test-lint/
            end

            expect(test_lint.none? { |node| node.disabled?(linter) }).to eq(true)
          end
        end
      end
    end

    context 'that is overriding other directives' do
      let(:source) do
        [
          '-# haml-lint:disable AltText',
          '%img{ src: "test-no-lint.png" }',
          '%div',
          '  %img{ src: "test-no-lint-2.png" }',
          '-# haml-lint:enable all',
          '%img{ src: "test-lint.png" }',
          '-# haml-lint:enable AltText',
          '%div',
          '  -# haml-lint:disable all',
          '  %img{src: "test-no-lint-3.png"}',
          '%img{src: "test-lint-2.png"}'
        ].join("\n")
      end

      describe '#disabled?' do
        subject { document.tree.select { |node| node.disabled?(linter) }.map(&:line) }

        context 'for the AltText linter' do
          let(:linter) { HamlLint::Linter::AltText.new(config) }

          it 'is disabled for the image tags for test-no-lint sources' do
            test_no_lint = document.tree.select do |node|
              node.type == :tag && node.source_code =~ /test-no-lint/
            end

            expect(test_no_lint.all? { |node| node.disabled?(linter) }).to eq(true)
          end

          it 'is not disabled for the image tags for test-lint sources' do
            test_lint = document.tree.select do |node|
              node.type == :tag && node.source_code =~ /test-lint/
            end

            expect(test_lint.none? { |node| node.disabled?(linter) }).to eq(true)
          end
        end
      end
    end
  end
end
