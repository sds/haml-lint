# frozen_string_literal: true

RSpec.describe HamlLint::Linter::StrictLocals do
  include_context 'linter'

  context 'when the file name does not match the matcher' do
    let(:haml) do
      [
        '%p= greeting',
        '%p{ title: greeting }',
        ':ruby',
        '  x = greeting'
      ].join("\n")
    end

    it { should_not report_lint }
  end

  context 'when the file name matches the matcher' do
    let(:options) do
      {
        config: HamlLint::ConfigurationLoader.default_configuration,
        file: '_partial.html.haml'
      }
    end

    context 'and there is a strict locals comment' do
      let(:haml) do
        [
          '-# locals: (greeting:)',
          '%p Hello, world'
        ].join("\n")
      end

      it { should_not report_lint }
    end

    context 'and there is a strict locals comment at the top of the file' do
      let(:haml) do
        <<~HAML
          -# haml-lint:disable ViewLength
          -# locals: (greeting:)
          %p Hello, world
        HAML
      end

      it { should_not report_lint }
    end

    context 'and there is no strict locals comment' do
      let(:haml) { '%p Hello, world' }

      it { should report_lint line: 1 }
    end

    context 'and there is a strict locals comment after other nodes' do
      let(:haml) do
        <<~HAML
          %p Hello, world
          -# locals: (greeting:)
        HAML
      end

      it { should report_lint line: 1 }
    end

    context 'and the linter is disabled by a comment' do
      let(:haml) do
        <<~HAML
          -# haml-lint:disable StrictLocals
          %p Hello, world
        HAML
      end

      it { should_not report_lint }
    end
  end

  context 'with a custom matcher' do
    let(:haml) { '%p= @greeting' }
    let(:full_config) do
      HamlLint::Configuration.new(
        'linters' => {
          'StrictLocals' => {
            'file_types' => 'my_custom',
            'matchers' => {
              'my_custom' => '\Apartial_.*\.haml\z'
            }
          }
        }
      )
    end

    let(:options) do
      {
        config: full_config,
        file: file
      }
    end

    context 'that matches the file name' do
      let(:file) { 'partial_view.html.haml' }

      it { should report_lint line: 1 }
    end

    context 'that does not match the file name' do
      let(:file) { 'view.html.haml' }

      it { should_not report_lint }
    end
  end
end
