require 'spec_helper'

describe HamlLint::Linter::ClassAttributeWithStaticValue do
  include_context 'linter'

  context 'when tag contains no class attribute' do
    let(:haml) { '%tag' }

    it { should_not report_lint }
  end

  context 'when tag contains static class attribute' do
    let(:haml) { '%tag.class' }

    it { should_not report_lint }
  end

  context 'when implicit div contains static class attribute' do
    let(:haml) { '.class' }

    it { should_not report_lint }
  end

  context 'when tag contains dynamic class attribute' do
    let(:haml) { '%tag{ class: status }' }

    it { should_not report_lint }
  end

  context 'when tag contains dynamic class attribute with symbol value' do
    let(:haml) { '%tag{ class: :status }' }

    it { should report_lint }
  end

  context 'when tag contains dynamic class attribute with string value' do
    let(:haml) { "%tag{ class: 'status' }" }

    it { should report_lint }
  end
end
