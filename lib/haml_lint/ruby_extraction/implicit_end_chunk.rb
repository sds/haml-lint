# frozen_string_literal: true

module HamlLint::RubyExtraction
  # HAML adds a `end` when code gets outdented. We need to add that to the Ruby too, this
  # is the chunk for it.
  # However:
  # * we can't apply fixes to it, so there are no markers
  # * this is a distinct class so that a ScriptChunk can fuse this ImplicitEnd into itself,
  #   So that we can generate bigger chunks of uninterrupted Ruby.
  class ImplicitEndChunk < BaseChunk
    def wrap_in_markers
      false
    end

    def transfer_correction(coordinator, all_corrected_ruby_lines, haml_lines); end
  end
end
