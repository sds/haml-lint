describe HamlLint::RubyParser do
  describe '#parse' do
    subject { super().parse(source) }

    context 'when given an empty string' do
      let(:source) { '' }

      it { should be_nil }
    end

    context 'when given a valid Ruby program' do
      let(:source) { "puts 'Hello World'" }

      it { should respond_to :children }
      it { should respond_to :type }
      it { should respond_to :parent }
      its(:type) { should == :send }
    end
  end
end
