require 'spec_helper'

describe HamlLint::Linter::ConsecutiveComments do
  include_context 'linter'

  context 'when single comment occupies multiple lines' do
    let(:haml) { <<-HAML }
      -# A multiline
         comment is
         nothing to fear
    HAML

    it { should_not report_lint }
  end

  context 'when consecutive comments occupy multiple lines' do
    let(:haml) { <<-HAML }
      -# A collection
      -# of many
      -# consecutive comments
      %tag
      .class
      -# Individual comment
      #id
      -# Another collection
      -# of consecutive comments
    HAML

    it { should report_lint line: 1 }
    it { should_not report_lint line: 6 }
    it { should report_lint line: 8 }
  end
end
