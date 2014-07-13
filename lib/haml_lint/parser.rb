require 'haml'

module HamlLint
  # Parses a HAML document for inspection by linters.
  class Parser
    attr_reader :contents, :filename, :lines, :tree

    def initialize(haml_or_filename)
      if File.exist?(haml_or_filename)
        @filename = haml_or_filename
        @contents = File.read(haml_or_filename)
      else
        @contents = haml_or_filename
      end

      @lines = @contents.split("\n")
      @tree = Haml::Parser.new(@contents, Haml::Options.new).parse
    end
  end
end
