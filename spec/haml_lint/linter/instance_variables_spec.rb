require 'spec_helper'

RSpec.describe HamlLint::Linter::InstanceVariables do
  include_context 'linter'

  context 'when the file name does not match the matcher' do
    let(:haml) { '%p= @greeting' }

    it { should_not report_lint }
  end

  context 'when the file name matches the matcher' do
    let(:options) do
      {
        config: HamlLint::ConfigurationLoader.default_configuration,
        file: '_partial.html.haml'
      }
    end

    context 'and there is not an instance variable' do
      let(:haml) { '%p Hello, world' }

      it { should_not report_lint }
    end

    context 'and there is an instance variable' do
      context 'in a tag node' do
        context 'as script' do
          let(:haml) { '%p= @greeting' }

          it { should report_lint line: 1 }
        end

        context 'as an attribute' do
          let(:haml) { '%p{ name: @greeting }' }

          it { should report_lint line: 1 }
        end
      end

      context 'in a script node' do
        let(:haml) { '= :blah && @greeting' }

        it { should report_lint line: 1 }
      end

      context 'in a silent script node' do
        let(:haml) { '- hello = @greeting' }

        it { should report_lint line: 1 }
      end
    end
  end

  context 'with a custom matcher' do
    let(:haml) { '%p= @greeting' }
    let(:full_config) do
      HamlLint::Configuration.new(
        'linters' => {
          'InstanceVariables' => {
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
