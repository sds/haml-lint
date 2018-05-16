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

  context 'when tag contains dynamic class attribute with method call value' do
    let(:haml) { '%th{ class: some_method_call }' }

    it { should_not report_lint }
  end

  context 'when tag contains dynamic class attribute with ivar value' do
    let(:haml) { '%th{ class: @some_ivar }' }

    it { should_not report_lint }
  end

  context 'when tag contains attributes assigned via method call' do
    let(:haml) { '%tag{ some_method_call }' }

    it { should_not report_lint }
  end

  context 'when tag attributes contain syntax errors' do
    let(:haml) { '%th{ :class: value }' }

    it { should_not report_lint }
  end

  context 'when tag attributes contain invalid value' do
    let(:haml) { "%th{ class: '{{value}}' }" }

    it { should_not report_lint }
  end

  context 'when tag attributes are malformed' do
    let(:haml) { %(%input{{type: "radio"}, "a" == "b" ? { checked: "checked" } : {}}) }

    it { should_not report_lint }
  end

  context 'when tag has both HTML-style and hash-style attributes' do
    let(:haml) { <<-HAML }
      - MyStruct = Struct.new(:href)
      - @title = 'Hello'
      - @link = MyStruct.new('blahblah')
      %a(title=@title){:href => @link.href} Stuff
    HAML

    it { should_not report_lint }
  end
end
