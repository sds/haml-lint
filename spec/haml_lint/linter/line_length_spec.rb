# frozen_string_literal: true

describe HamlLint::Linter::LineLength do
  include_context 'linter'

  context 'when a file contains lines which are too long' do
    let(:haml) do
      [
        '%p',
        '  = link_to "Foobar", i_need_to_make_this_line_longer_path, class: "button alert"',
        '  This line should be short'
      ].join("\n")
    end

    it { should_not report_lint line: 1 }
    it { should report_lint line: 2 }
    it { should_not report_lint line: 3 }

    context 'but the linter is disabled in the file' do
      let(:haml) { "-# haml-lint:disable LineLength\n" + super() }

      it { should_not report_lint }
    end
  end

  context 'when a file does not contain lines which are too long' do
    let(:haml) { <<-HAML }
      %p
        = link_to 'Foo', i_need_to_make_this_line_longer_path,
            class: 'button alert'
    HAML

    it { should_not report_lint }
  end

  context 'when a file contains lines within a multiline node that are too long' do
    let(:haml) do
      [
        '- if model.setup_state_manual?',
        "  = render 'no_validators_box'",
        '',
        ':ruby',
        '  active_engines = model.validators.active.to_a',
        '  engines = ::BlaBlaBlaBlaBlaBlaBlaBla.decorate_collection(::BlaBlaBlaBlaBla.all)',
      ].join("\n")
    end

    it { should report_lint line: 6 }
  end

  context 'when there is a directive on the line before a multiline pipe' do
    let(:haml) do
      <<-HAML
        -# haml-lint:disable LineLength
        %p{ |
          'data-test' => link_to 'Foobar', i_need_to_make_this_line_longer_path, class: 'button alert' } |
        -# haml-lint:enable LineLength
        %p Another really long line that should report a lint for line length because it is no longer disabled
      HAML
    end

    it { should_not report_lint line: 3 }
    it { should report_lint line: 5 }
  end

  context 'when there is a directive on the line before a long line' do
    let(:haml) do
      <<-HAML
        #test
          -# haml-lint:disable LineLength
          %table.responsive.table.table-sm.table-striped.table-bordered.w-100#excluded-requests-datatable{ data: 'excluded_requests_remote_url(@staging_workflow.id)' }
          %br
      HAML
    end

    it { should_not report_lint }
  end
end
