# frozen_string_literal: true

describe HamlLint::Linter::RuboCop do
  context 'autocorrect' do
    include_context 'rubocop_autocorrect'

    Dir[__dir__ + '/rubocop_autocorrect_examples/*_examples.txt'].each do |path|
      file_name = File.basename(path)
      examples_from(path).each do |example|
        context "(#{file_name}:#{example.first_line_no}) #{example.name}" do
          let(:steps_string) { example.string }

          let(:options) { super().merge(file: path) }

          it { follows_steps }
        end
      end
    end

    # TO TEST: %tag #{expression}
  end
end
