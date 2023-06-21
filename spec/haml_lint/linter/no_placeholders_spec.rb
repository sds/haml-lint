# frozen_string_literal: true

describe HamlLint::Linter::NoPlaceholders do
  include_context 'linter'

  context 'with a generic tag' do
    let(:haml) { '%tag' }

    it { should_not report_lint }
  end

  context 'when a tag has an unrelated hash attribute with placeholder as a value' do
    let(:haml) { "%tag{ unrelated_attribute: 'placeholder' }" }

    it { should_not report_lint }
  end

  ['placeholder:',
   'placeholder: ',
   "'placeholder':",
   '"placeholder":',
   ':placeholder=>',
   ':placeholder => ',
   "'placeholder' => ",
   '"placeholder" => '].each do |key_format|
    context 'when tag has a hash-style placeholder attribute' do
      let(:haml) { "%tag{ #{key_format}'my placeholder' } " }

      it { should report_lint(count: 1) }
      it { should report_lint(message: 'Placeholders attributes should not be used.') }
    end
  end

  context 'when a tag has an html-style placeholder attribute' do
    let(:haml) { '%tag(placeholder="my placeholder")' }

    it { should report_lint(count: 1) }
    it { should report_lint(message: 'Placeholders attributes should not be used.') }
  end
end
