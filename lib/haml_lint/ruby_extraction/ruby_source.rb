# frozen_string_literal: true

module HamlLint::RubyExtraction
  RubySource = Struct.new(:source, :source_map, :ruby_chunks)
end
