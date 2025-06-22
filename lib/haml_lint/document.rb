# frozen_string_literal: true

require_relative 'adapter'

module HamlLint
  # Represents a parsed Haml document and its associated metadata.
  class Document
    # File name given to source code parsed from just a string.
    STRING_SOURCE = '(string)'

    # @return [HamlLint::Configuration] Configuration used to parse template
    attr_reader :config

    # @return [String] Haml template file path
    attr_reader :file

    # @return [Boolean] true if source was read directly from `file` on-disk (rather than from stdin)
    attr_reader :file_on_disk

    # @return [Boolean] true if source changes (from autocorrect) should be written to stdout instead of disk
    attr_reader :write_to_stdout

    # @return [HamlLint::Tree::Node] Root of the parse tree
    attr_reader :tree

    # @return [String] original source code
    attr_reader :source

    # @return [Array<String>] original source code as an array of lines
    attr_reader :source_lines

    # @return [Boolean] true if the source was changed (by autocorrect)
    attr_reader :source_was_changed

    # @return [String] the indentation used in the file
    attr_reader :indentation

    attr_reader :unescape_interpolation_to_original_cache

    # Parses the specified Haml code into a {Document}.
    #
    # @param source [String] Haml code to parse
    # @param options [Hash]
    # @option options :file [String] file name of document that was parsed
    # @option options :file_on_disk [Boolean] true if source was read straight from `file` on disk
    # @option options :write_to_stdout [Boolean] true if source changes should be written to stdout
    # @raise [Haml::Parser::Error] if there was a problem parsing the document
    def initialize(source, options)
      @config = options[:config]
      @file = options.fetch(:file, STRING_SOURCE)
      @write_to_stdout = options[:write_to_stdout]
      @file_on_disk = options[:file_on_disk] && @file != STRING_SOURCE
      @source_was_changed = false
      process_source(source)
    end

    # Returns the last non empty line of the document or 1 if all lines are empty
    #
    # @return [Integer] last non empty line of the document or 1 if all lines are empty
    def last_non_empty_line
      index = source_lines.rindex { |l| !l.empty? }
      (index || 0) + 1
    end

    # Reparses the new source and remember that the document was changed
    # Used when auto-correct does changes to the file. If the source hasn't changed,
    # then the document will not be marked as changed.
    #
    # If the new_source fails to parse, automatically reparses the previous source
    # to bring the document back to how it should be before re-raising the parse exception
    #
    # @param source [String] Haml code to parse
    def change_source(new_source)
      return if new_source == @source
      check_new_source_compatible(new_source)

      old_source = @source
      begin
        process_source(new_source)
        @source_was_changed = true
      rescue HamlLint::Exceptions::ParseError
        # Reprocess the previous_source so that other linters can work on this document
        # object from a clean slate
        process_source(old_source)
        raise
      end
      nil
    end

    def write_to_disk!
      return unless @source_was_changed
      if file == STRING_SOURCE
        raise HamlLint::Exceptions::InvalidFilePath, 'Cannot write without :file option'
      end
      if @write_to_stdout
        $stdout << unstrip_frontmatter(source)
      else
        File.write(file, unstrip_frontmatter(source))
      end
      @source_was_changed = false
    end

    private

    # @param source [String] Haml code to parse
    # @raise [HamlLint::Exceptions::ParseError] if there was a problem parsing
    def process_source(source) # rubocop:disable Metrics/MethodLength
      @source = process_encoding(source)
      @source = strip_frontmatter(source)
      # the -1 is to keep the empty strings at the end of the array when the source
      # ended with multiple new-lines
      @source_lines = @source.split(/\r\n|\r|\n/, -1)
      adapter = HamlLint::Adapter.detect_class.new(@source)
      parsed_tree = adapter.parse
      @indentation = adapter.send(:parser).instance_variable_get(:@indentation)
      @tree = process_tree(parsed_tree)
      @unescape_interpolation_to_original_cache =
        Haml::Util.unescape_interpolation_to_original_cache_take_and_wipe
    rescue Haml::Error => e
      location = if e.line
                   "#{@file}:#{e.line}"
                 else
                   @file
                 end
      msg = if ENV['HAML_LINT_DEBUG'] == 'true'
              "#{location} (DEBUG: source follows) - #{e.message}\n#{source}\n------"
            else
              "#{location} - #{e.message}"
            end
      error = HamlLint::Exceptions::ParseError.new(msg, e.line)
      raise error
    end

    # Processes the {Haml::Parser::ParseNode} tree and returns a tree composed
    # of friendlier {HamlLint::Tree::Node}s.
    #
    # @param original_tree [Haml::Parser::ParseNode]
    # @return [Haml::Tree::Node]
    def process_tree(original_tree)
      # Remove the trailing empty HAML comment that the parser creates to signal
      # the end of the HAML document
      if Gem::Requirement.new('~> 4.0.0').satisfied_by?(Gem.loaded_specs['haml'].version)
        original_tree.children.pop
      end

      @node_transformer = HamlLint::NodeTransformer.new(self)
      convert_tree(original_tree)
    end

    # Converts a HAML parse tree to a tree of {HamlLint::Tree::Node} objects.
    #
    # This provides a cleaner interface with which the linters can interact with
    # the parse tree.
    #
    # @param haml_node [Haml::Parser::ParseNode]
    # @param parent [Haml::Tree::Node]
    # @return [Haml::Tree::Node]
    def convert_tree(haml_node, parent = nil)
      new_node = @node_transformer.transform(haml_node)
      new_node.parent = parent

      new_node.children = haml_node.children.map do |child|
        convert_tree(child, new_node)
      end

      new_node
    end

    # Ensures source code is interpreted as UTF-8.
    #
    # This is necessary as sometimes Ruby guesses the encoding of a file
    # incorrectly, for example if the LC_ALL environment variable is set to "C".
    # @see http://unix.stackexchange.com/a/87763
    #
    # @param source [String]
    # @return [String] source encoded with UTF-8 encoding
    def process_encoding(source)
      source.force_encoding(Encoding::UTF_8)
    end

    # Removes YAML frontmatter
    def strip_frontmatter(source)
      frontmatter = /
        # From the start of the string
        \A
        # First-capture match --- followed by optional whitespace up
        # to a newline then 0 or more chars followed by an optional newline.
        # This matches the --- and the contents of the frontmatter
        (---\s*\n.*?\n?)
        # From the start of the line
        ^
        # Second capture match --- or ... followed by optional whitespace
        # and newline. This matches the closing --- for the frontmatter.
        (---|\.\.\.)\s*$\n?/mx

      if config['skip_frontmatter'] && match = source.match(frontmatter)
        @stripped_frontmatter = match[0]
        @nb_newlines_for_frontmatter = match[0].count("\n")
        source.sub!(frontmatter, "\n" * @nb_newlines_for_frontmatter)
      end

      source
    end

    def check_new_source_compatible(new_source)
      if @stripped_frontmatter && !new_source.start_with?("\n" * @nb_newlines_for_frontmatter)
        raise HamlLint::Exceptions::IncompatibleNewSource,
              "Internal error: new_source doesn't start with enough newlines for the Front Matter that was stripped"
      end
    end

    def unstrip_frontmatter(source)
      return source unless @stripped_frontmatter
      check_new_source_compatible(source)

      source.sub("\n" * @nb_newlines_for_frontmatter, @stripped_frontmatter)
    end
  end
end
