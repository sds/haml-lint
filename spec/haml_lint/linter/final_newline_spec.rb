require 'spec_helper'

describe HamlLint::Linter::FinalNewline do
  include_context 'linter'

  context 'when trailing newline is preferred' do
    let(:config) { super().merge('present' => true) }

    context 'when the file is empty' do
      let(:haml) { '' }

      it { should_not report_lint }
    end

    context 'when the file ends with a newline' do
      let(:haml) { "%span\n" }

      it { should_not report_lint }
    end

    context 'when the file does not end with a newline' do
      let(:haml) { '%span' }

      it { should report_lint line: 1 }
    end
  end

  context 'when no trailing newline is preferred' do
    let(:config) { super().merge('present' => false) }

    context 'when the file is empty' do
      let(:haml) { '' }

      it { should_not report_lint }
    end

    context 'when the file ends with a newline' do
      let(:haml) { "%span\n" }

      it { should report_lint line: 1 }
    end

    context 'when the file does not end with a newline' do
      let(:haml) { '%span' }

      it { should_not report_lint }
    end
  end
end
