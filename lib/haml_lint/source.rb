# frozen_string_literal: true

module HamlLint
  # Wrapper class representing a single target for HamlLint::Runner to run against, comprised of a file path to
  # eventually read from, and an optional IO argument to override with.
  class Source
    # @return [String] File path associated with the given IO object.
    attr_reader :path

    # Wraps an optional IO object and file path to a source object.
    #
    # @param [String] path
    # @param [IO] io
    def initialize(path: nil, io: nil)
      @path = path
      @io = io
    end

    # @return [String] Contents of the given IO object.
    def contents
      @contents ||= @io&.read || File.read(path)
    end

    # @return [boolean] true if we're reading from stdin rather than a file path
    def stdin?
      !@io.nil?
    end
  end
end
