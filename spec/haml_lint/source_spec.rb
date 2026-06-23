# frozen_string_literal: true

describe HamlLint::Source do
  describe '#contents' do
    include_context 'isolated environment'

    before do
      File.write('example.haml', "%p hello\n")
      Dir.mkdir('other')
    end

    it 'reads from the original file location if the working directory changes' do
      source = described_class.new(path: 'example.haml')

      Dir.chdir('other') do
        source.contents.should == "%p hello\n"
      end
    end
  end
end
