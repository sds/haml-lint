RSpec.describe HamlLint::Linter::IdNames do
  include_context 'linter'

  context 'when there is no id' do
    let(:haml) { '%div' }

    context 'default config (lisp_case)' do
      it { should_not report_lint }
    end

    context 'with camel_case config' do
      let(:config) { super().merge('style' => 'camel_case') }

      it { should_not report_lint }
    end

    context 'with pascal_case config' do
      let(:config) { super().merge('style' => 'pascal_case') }

      it { should_not report_lint }
    end

    context 'with snake_case config' do
      let(:config) { super().merge('style' => 'snake_case') }

      it { should_not report_lint }
    end
  end

  context 'when there is a one-word, lowercase id' do
    let(:haml) { '#name' }

    context 'default config (lisp_case)' do
      it { should_not report_lint }
    end

    context 'with camel_case config' do
      let(:config) { super().merge('style' => 'camel_case') }

      it { should_not report_lint }
    end

    context 'with pascal_case config' do
      let(:config) { super().merge('style' => 'pascal_case') }

      it { should report_lint line: 1, message: '`id` attribute must be in PascalCase' }
    end

    context 'with snake_case config' do
      let(:config) { super().merge('style' => 'snake_case') }

      it { should_not report_lint }
    end
  end

  context 'when there is a Lisp case id' do
    let(:haml) { '#lisp-case' }

    context 'default config (lisp_case)' do
      it { should_not report_lint }
    end

    context 'with camel_case config' do
      let(:config) { super().merge('style' => 'camel_case') }

      it { should report_lint line: 1, message: '`id` attribute must be in camelCase' }
    end

    context 'with pascal_case config' do
      let(:config) { super().merge('style' => 'pascal_case') }

      it { should report_lint line: 1, message: '`id` attribute must be in PascalCase' }
    end

    context 'with snake_case config' do
      let(:config) { super().merge('style' => 'snake_case') }

      it { should report_lint line: 1, message: '`id` attribute must be in snake_case' }
    end
  end

  context 'when there is a camel case id' do
    let(:haml) { '#camelCase' }

    context 'default config (lisp_case)' do
      it { should report_lint line: 1, message: '`id` attribute must be in lisp-case' }
    end

    context 'with camel_case config' do
      let(:config) { super().merge('style' => 'camel_case') }

      it { should_not report_lint }
    end

    context 'with pascal_case config' do
      let(:config) { super().merge('style' => 'pascal_case') }

      it { should report_lint line: 1, message: '`id` attribute must be in PascalCase' }
    end

    context 'with snake_case config' do
      let(:config) { super().merge('style' => 'snake_case') }

      it { should report_lint line: 1, message: '`id` attribute must be in snake_case' }
    end
  end

  context 'when there is a Pascal case id' do
    let(:haml) { '#PascalCase' }

    context 'default config (lisp_case)' do
      it { should report_lint line: 1, message: '`id` attribute must be in lisp-case' }
    end

    context 'with camel_case config' do
      let(:config) { super().merge('style' => 'camel_case') }

      it { should report_lint line: 1, message: '`id` attribute must be in camelCase' }
    end

    context 'with pascal_case config' do
      let(:config) { super().merge('style' => 'pascal_case') }

      it { should_not report_lint }
    end

    context 'with snake_case config' do
      let(:config) { super().merge('style' => 'snake_case') }

      it { should report_lint line: 1, message: '`id` attribute must be in snake_case' }
    end
  end

  context 'when there is a snake case id' do
    let(:haml) { '#snake_case' }

    context 'default config (lisp_case)' do
      it { should report_lint line: 1, message: '`id` attribute must be in lisp-case' }
    end

    context 'with camel_case config' do
      let(:config) { super().merge('style' => 'camel_case') }

      it { should report_lint line: 1, message: '`id` attribute must be in camelCase' }
    end

    context 'with pascal_case config' do
      let(:config) { super().merge('style' => 'pascal_case') }

      it { should report_lint line: 1, message: '`id` attribute must be in PascalCase' }
    end

    context 'with snake_case config' do
      let(:config) { super().merge('style' => 'snake_case') }

      it { should_not report_lint }
    end
  end
end
