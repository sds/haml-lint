# frozen_string_literal: true

module HamlLint
  # Wrapper class representing a single target for HamlLint::Runner to run against, comprised of an IO object
  # containing haml code, as well as a file path.
  class Source
    # @return [String] File path associated with the given IO object.
    attr_reader :path

    # Wraps an IO object and file path to a source object.
    #
    # @param [IO] io
    # @param [String] path
    def initialize(io, path)
      @io = io
      @path = path
    end

    # @return [String] Contents of the given IO object.
    def contents
      @contents ||= @io.read
    end
  end
end
