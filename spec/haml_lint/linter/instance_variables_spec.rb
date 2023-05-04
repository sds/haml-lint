# frozen_string_literal: true

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

      context 'single line if in a script node' do
        let(:haml) { '= if conditional; @true; else false; end' }

        it { should report_lint line: 1 }
      end

      context 'single line if in a silent script node' do
        let(:haml) { '- result = if conditional; true; else @false; end' }

        it { should report_lint line: 1 }
      end

      context 'as an if conditional' do
        let(:haml) do
          [
            '- if @conditional',
            '  %p true'
          ].join("\n")
        end

        it { should report_lint line: 1 }
      end

      context 'as an elsif conditional' do
        let(:haml) do
          [
            '- if false',
            '  %p first',
            '- elsif @conditional',
            '  %p second'
          ].join("\n")
        end

        it { should report_lint line: 3 }
      end

      context 'as an unless conditional' do
        let(:haml) do
          [
            '- unless @conditional',
            '  %p false'
          ].join("\n")
        end

        it { should report_lint line: 1 }
      end

      context 'as a while conditional' do
        let(:haml) do
          [
            '- while @conditional',
            '  %p loop'
          ].join("\n")
        end

        it { should report_lint line: 1 }
      end

      context 'as an until conditional' do
        let(:haml) do
          [
            '- until @conditional',
            '  %p loop'
          ].join("\n")
        end

        it { should report_lint line: 1 }
      end

      context 'for loop in a script node' do
        let(:haml) do
          [
            '= for item in @list',
            '  - item'
          ].join("\n")
        end

        it { should report_lint line: 1 }
      end

      context 'for loop in a silent script node' do
        let(:haml) do
          [
            '- for item in @list',
            '  = item'
          ].join("\n")
        end

        it { should report_lint line: 1 }
      end

      context 'with an iterator in a script node' do
        let(:haml) do
          [
            '= @list.each do |item|',
            '  - item'
          ].join("\n")
        end

        it { should report_lint line: 1 }
      end

      context 'with an iterator in a silent script node' do
        let(:haml) do
          [
            '- @list.each do |item|',
            '  = item'
          ].join("\n")
        end

        it { should report_lint line: 1 }
      end

      context 'single line case in a script node' do
        let(:haml) { '= case variable; when 1; @one; end' }

        it { should report_lint line: 1 }
      end

      context 'single line case in a silent script node' do
        let(:haml) { '- value = case @variable; when 1; one; end' }

        it { should report_lint line: 1 }
      end

      context 'as a case variable in a script node' do
        let(:haml) do
          [
            '= case @variable',
            '- when 1',
            '  - one'
          ].join("\n")
        end

        it { should report_lint line: 1 }
      end

      context 'as a case variable in a silent script node' do
        let(:haml) do
          [
            '- case @variable',
            '- when 1',
            '  %p one'
          ].join("\n")
        end

        it { should report_lint line: 1 }
      end

      context 'as a when condition' do
        let(:haml) do
          [
            '- case variable',
            '- when @value',
            '  %p value'
          ].join("\n")
        end

        it { should report_lint line: 2 }
      end

      context 'as a rescue error class' do
        let(:haml) do
          [
            '- begin',
            '- rescue @error',
            '  %p error'
          ].join("\n")
        end

        it { should report_lint line: 2 }
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

  context 'when the partial is actually an ERB file that writes Haml' do
    # Using :run to see the handling of the generated exception
    let(:run_method_to_use) { :run }

    let(:options) do
      {
        config: HamlLint::ConfigurationLoader.default_configuration,
        file: '_partial.html.haml'
      }
    end

    let(:haml) do
      [
        '<%- model_attrs.each do |attr| -%>',
        '= form.text_field :<%= attr.name %>',
        '<%- end -%>',
        '',
        '= form.form_group :class => "form-actions" do',
        '  = form.hidden_tag @ivar',
        '  = form.submit :class => "btn btn-primary"'
      ].join("\n")
    end

    it 'does not raise an error' do
      expect { subject }.not_to raise_error
    end

    # With ruby 2.7 & v3 of the Parser gem, we can now skip past the 'invalid' ERB syntax
    if RUBY_VERSION < '2.7'
      it { should report_lint line: 1, message: 'unterminated string meets end of file' }
    else
      it { should report_lint line: 6, message: 'Avoid using instance variables in partials views' }
    end
  end
end
