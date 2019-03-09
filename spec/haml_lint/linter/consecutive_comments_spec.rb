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

    context 'but the linter is disabled in the file' do
      let(:haml) { "-# haml-lint:disable ConsecutiveComments\n" + super() }

      it { should_not report_lint }
    end
  end

  context 'when the max_consecutive option is set' do
    let(:config) { super().merge('max_consecutive' => 3) }
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
      -# and another one
      -# and another one
    HAML

    it { should_not report_lint line: 1 }
    it { should_not report_lint line: 6 }
    it { should report_lint line: 8 }

    context 'but the linter is disabled in the file' do
      let(:haml) { "-# haml-lint:disable ConsecutiveComments\n" + super() }

      it { should_not report_lint }
    end
  end
end
