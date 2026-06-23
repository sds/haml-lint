# frozen_string_literal: true

describe HamlLint::Linter::UnescapedHtml do
  include_context 'linter'

  context 'when a script uses the escaped `=` marker' do
    let(:haml) { '= user_input' }
    it { should_not report_lint }
  end

  context 'when a script uses the unescaped `!=` marker' do
    let(:haml) { '!= user_input' }
    it { should report_lint line: 1 }
  end

  context 'when a script uses the unescaped preserve `!~` marker' do
    let(:haml) { '!~ user_input' }
    it { should report_lint line: 1 }
  end

  context 'when a script uses the escaped preserve `~` marker' do
    let(:haml) { '~ user_input' }
    it { should_not report_lint }
  end

  context 'when plain text is output unescaped with interpolation' do
    let(:haml) { '! Hello #{user.name}' }
    it { should report_lint line: 1 }
  end

  context 'when plain text is static (no unescape marker is meaningful)' do
    let(:haml) { 'Just some static text' }
    it { should_not report_lint }
  end

  context 'when a tag uses `!` on static text with no interpolation' do
    let(:haml) { '%p! Just static text' }
    it { should_not report_lint }
  end

  context 'when a tag uses the escaped `=` marker' do
    let(:haml) { '%p= user_input' }
    it { should_not report_lint }
  end

  context 'when a tag uses the unescaped `!=` marker' do
    let(:haml) { '%p!= user_input' }
    it { should report_lint line: 1 }
  end

  context 'when a tag uses the unescaped preserve `!~` marker' do
    let(:haml) { '%p!~ user_input' }
    it { should report_lint line: 1 }
  end

  context 'when a tag with classes and ids uses `!=`' do
    let(:haml) { '%p.card#main!= user_input' }
    it { should report_lint line: 1 }
  end

  context 'when a tag with hash attributes uses `!=`' do
    let(:haml) { '%p{ title: "t" }!= user_input' }
    it { should report_lint line: 1 }
  end

  context 'when a tag combines whitespace removal with `!=`' do
    let(:haml) { '%p<>!= user_input' }
    it { should report_lint line: 1 }
  end

  context 'when a tag uses whitespace removal with the escaped `=` marker' do
    let(:haml) { '%p<>= user_input' }
    it { should_not report_lint }
  end

  context 'when a tag has no inline script' do
    let(:haml) { '%p' }
    it { should_not report_lint }
  end

  context 'when escaped output contains the Ruby `!=` operator' do
    let(:haml) { '= a != b' }
    it { should_not report_lint }
  end

  context 'when an escaped tag contains the Ruby `!=` operator' do
    let(:haml) { '%p= a != b' }
    it { should_not report_lint }
  end

  context 'when a silent script contains the Ruby `!=` operator' do
    let(:haml) { '- foo if a != b' }
    it { should_not report_lint }
  end

  context 'when multiple unescaped markers are used' do
    let(:haml) do
      [
        '!= first',
        '%p!= second',
        '! third #{value}',
      ].join("\n")
    end

    it { should report_lint count: 3 }
    it { should report_lint line: 1 }
    it { should report_lint line: 2 }
    it { should report_lint line: 3 }
  end
end
