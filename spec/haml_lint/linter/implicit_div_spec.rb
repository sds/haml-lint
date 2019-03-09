describe HamlLint::Linter::ImplicitDiv do
  include_context 'linter'

  context 'when a div tag has no classes or IDs' do
    let(:haml) { <<-HAML }
      %div Hello
    HAML

    it { should_not report_lint }
  end

  context 'when a div tag has a class' do
    let(:haml) { <<-HAML }
      %div.container Hello
    HAML

    it { should report_lint line: 1 }
  end

  context 'when a div has an ID' do
    let(:haml) { <<-HAML }
      %div#container Hello
    HAML

    it { should report_lint line: 1 }
  end

  context 'when a nameless tag has a class' do
    let(:haml) { <<-HAML }
      .container Hello
    HAML

    it { should_not report_lint }
  end

  context 'when a nameless tag has an ID' do
    let(:haml) { <<-HAML }
      #container Hello
    HAML

    it { should_not report_lint }
  end

  context 'when a div with a class is deeply nested' do
    let(:haml) { <<-HAML }
      %tag
        %child
          %div.container
    HAML

    it { should report_lint line: 3 }
  end

  context 'when a div has ruby code inside curly braces' do
    let(:haml) { <<-HAML }
      %div{ id: Object.to_s }
    HAML

    it { should_not report_lint }
  end

  context 'when div has ruby code inside square braces' do
    let(:haml) { <<-HAML }
      %div[Object.to_s]
    HAML

    it { should_not report_lint }
  end
end
