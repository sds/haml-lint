require 'spec_helper'

describe HamlLint::FileFinder do
  let(:config) { double }
  let(:excluded_patterns) { [] }

  subject { described_class.new(config) }

  describe '#find' do
    include_context 'isolated environment'

    subject { super().find(patterns, excluded_patterns) }

    context 'when no patterns are given' do
      let(:patterns) { [] }

      context 'and there are no HAML files under the current directory' do
        it { should == [] }
      end

      context 'and there are HAML files under the current directory' do
        before do
          `touch blah.haml`
          `mkdir -p more`
          `touch more/more.haml`
        end

        it { should == [] }
      end
    end

    context 'when files without a valid extension are given' do
      let(:patterns) { ['test.txt'] }

      context 'and those files exist' do
        before do
          `touch test.txt`
        end

        it { should == ['test.txt'] }
      end

      context 'and those files do not exist' do
        it 'raises an error' do
          expect { subject }.to raise_error HamlLint::Exceptions::InvalidFilePath
        end
      end
    end

    context 'when directories are given' do
      let(:patterns) { ['some-dir'] }

      context 'and those directories exist' do
        before do
          `mkdir -p some-dir`
        end

        context 'and they contain HAML files' do
          before do
            `touch some-dir/test.haml`
          end

          it { should == ['some-dir/test.haml'] }
        end

        context 'and they contain more directories with files with recognized extensions' do
          before do
            `mkdir -p some-dir/more-dir`
            `touch some-dir/more-dir/test.haml`
          end

          it { should == ['some-dir/more-dir/test.haml'] }
        end

        context 'and they contain files with some other extension' do
          before do
            `touch some-dir/test.txt`
          end

          it { should == [] }
        end
      end

      context 'and those directories do not exist' do
        it 'raises an error' do
          expect { subject }.to raise_error HamlLint::Exceptions::InvalidFilePath
        end
      end
    end

    context 'when the same file is specified multiple times' do
      let(:patterns) { ['test.haml'] * 3 }

      before do
        `touch test.haml`
      end

      it { should == ['test.haml'] }
    end
  end
end
