require 'spec_helper'
require 'haml_lint/logger'

describe HamlLint::Logger do
  let(:io)     { StringIO.new }
  let(:logger) { described_class.new(io) }

  describe '#color_enabled' do
    subject { logger.send :color_enabled }

    describe 'output is a tty' do
      before { io.stub(:tty?).and_return(true) }

      it { should eq true }
    end

    describe 'output is not a tty' do
      before { io.stub(:tty?).and_return(false) }

      it { should eq false }
    end

    describe 'color_enabled set to true' do
      before { logger.color_enabled = true }

      it { should eq true }
    end

    describe 'tty is nil and color_enabled is nil' do
      before do
        io.stub(:tty?).and_return(nil)
        logger.color_enabled = nil
      end

      it { should eq false }
    end
  end
end
