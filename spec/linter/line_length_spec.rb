require 'spec_helper'

describe HamlLint::Linter::LineLength do
  include_context 'linter'

  context 'when a file contains lines which are too long' do
    let(:haml) { <<-HAML }
      %p
        = link_to 'Foobar', i_need_to_make_this_line_longer_path, class: 'button alert'
        This line should be short
    HAML

    it { should_not report_lint line: 1 }
    it { should report_lint line: 2 }
    it { should_not report_lint line: 3 }
  end

  context 'when a file does not contain lines which are too long' do
    let(:haml) { <<-HAML }
      %p
        = link_to 'Foo', i_need_to_make_this_line_longer_path,
            class: 'button alert'
    HAML

    it { should_not report_lint }
  end
end
