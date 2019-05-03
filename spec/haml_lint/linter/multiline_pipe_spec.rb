# frozen_string_literal: true

describe HamlLint::Linter::MultilinePipe do
  include_context 'linter'

  context 'when a multiline block of code splits on commas' do
    let(:haml) { <<-HAML }
      = link_to 'Click Here',
                some_path,
                class: 'button link'
    HAML

    it { should_not report_lint }
  end

  context 'when code spans only one line' do
    let(:haml) { '%p= This is an #{adjective} experience' }
    it { should_not report_lint }
  end

  context 'when tag content contains a pipe' do
    let(:haml) { '%p One | Two | Three' }
    it { should_not report_lint }
  end

  context 'when tag content ends with an escaped pipe character' do
    let(:haml) { '%p This is a pipe character -> \|' }
    it { should_not report_lint }
  end

  context 'when tag content ends with a pipe character with no space before it' do
    let(:haml) { <<-HAML }
      %p
        What|
        Are|
        You|
    HAML

    it { should_not report_lint }
  end

  context 'when text content consists of just a pipe character for inline text' do
    let(:haml) { '%p |' }
    it { should report_lint line: 1 }
  end

  context 'when plain text consists of just a pipe' do
    let(:haml) { <<-HAML }
      %p
        |
    HAML

    it { should_not report_lint }
  end

  context 'when tag script content uses a pipe to separate lines' do
    let(:haml) { <<-HAML }
      %p= "What" +  |
          "could" + |
          "this" +  |
          "be?"     |
    HAML

    it { should report_lint line: 1 }
    it { should_not report_lint line: 2 }
    it { should_not report_lint line: 3 }
    it { should_not report_lint line: 4 }
  end

  context 'when script uses a pipe to separate lines' do
    let(:haml) { <<-HAML }
      = script +     |
        script_two + |
        script_three |
    HAML

    it { should report_lint line: 1 }
    it { should_not report_lint line: 2 }
    it { should_not report_lint line: 3 }
  end

  context 'when silent script uses a pipe to separate lines' do
    let(:haml) { <<-HAML }
      - script +     |
        script_two + |
        script_three |
    HAML

    it { should report_lint line: 1 }
    it { should_not report_lint line: 2 }
    it { should_not report_lint line: 3 }
  end
end
