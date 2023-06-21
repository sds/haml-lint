# frozen_string_literal: true

# Makes writing tests for linters a lot DRYer by taking any currently `haml`
# variable defined via `let` and normalizing it and running the linter against
# it, allowing specs to simply specify whether a lint was reported.

module HamlLint
  module Spec
    module SharedLinterContext
      RSpec.shared_context 'linter' do
        let(:options) do
          {
            config: HamlLint::ConfigurationLoader.default_configuration,
          }
        end

        let(:autocorrect) { nil }

        let(:config) { options[:config].for_linter(described_class) }

        let(:document) { HamlLint::Document.new(normalize_indent(haml), options) }

        # :run_or_raise, :run, or nil to not auto-call something
        let(:run_method_to_use) { :run_or_raise }

        subject { described_class.new(config) }

        before do
          next unless run_method_to_use
          subject.send(run_method_to_use, document, autocorrect: autocorrect)
        end
      end
    end
  end
end
