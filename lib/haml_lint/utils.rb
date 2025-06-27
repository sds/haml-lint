# frozen_string_literal: true

require 'pathname'

module HamlLint
  # A miscellaneous set of utility functions.
  module Utils # rubocop:disable Metrics/ModuleLength
    module_function

    # Returns whether a glob pattern (or any of a list of patterns) matches the
    # specified file.
    #
    # This is defined here so our file globbing options are consistent
    # everywhere we perform globbing.
    #
    # @param glob [String, Array]
    # @param file [String]
    # @return [Boolean]
    def any_glob_matches?(globs_or_glob, file)
      get_abs_and_rel_path(file).any? do |path|
        Array(globs_or_glob).any? do |glob|
          ::File.fnmatch?(glob, path,
                          ::File::FNM_PATHNAME | # Wildcards don't match path separators
                          ::File::FNM_DOTMATCH)  # `*` wildcard matches dotfiles
        end
      end
    end

    # Returns an array of two items, the first being the absolute path, the second
    # the relative path.
    #
    # The relative path is relative to the current working dir. The path passed can
    # be either relative or absolute.
    #
    # @param path [String] Path to get absolute and relative path of
    # @return [Array<String>] Absolute and relative path
    def get_abs_and_rel_path(path)
      original_path = Pathname.new(path)
      root_dir_path = Pathname.new(File.expand_path(Dir.pwd))

      if original_path.absolute?
        [path, original_path.relative_path_from(root_dir_path)]
      else
        [root_dir_path + original_path, path]
      end
    end

    # Yields interpolated values within a block of text.
    #
    # @param text [String]
    # @yield Passes interpolated code and line number that code appears on in
    #   the text.
    # @yieldparam interpolated_code [String] code that was interpolated
    # @yieldparam line [Integer] line number code appears on in text
    def extract_interpolated_values(text) # rubocop:disable Metrics/AbcSize
      dumped_text = text.dump

      # Basically, match pairs of '\' and '\ followed by the letter 'n'
      quoted_regex_s = "(#{Regexp.quote('\\\\')}|#{Regexp.quote('\\n')})"
      newline_positions = extract_substring_positions(dumped_text, quoted_regex_s)

      # Filter the matches to only keep those ending in 'n'.
      # This way, escaped \n will not be considered
      newline_positions.select! do |pos|
        dumped_text[pos - 1] == 'n'
      end

      Haml::Util.handle_interpolation(dumped_text) do |scan|
        line = (newline_positions.find_index { |marker| scan.charpos <= marker } ||
                newline_positions.size) + 1

        escape_count = (scan[2].size - 1) / 2
        break unless escape_count.even?

        dumped_interpolated_str = Haml::Util.balance(scan, '{', '}', 1)[0][0...-1]

        # Hacky way to turn a dumped string back into a regular string
        yield [eval('"' + dumped_interpolated_str + '"'), line] # rubocop:disable Security/Eval
      end
    end

    def handle_interpolation_with_indexes(text)
      newline_indexes = extract_substring_positions(text, "\n")

      handle_interpolation_with_newline(text) do |scan|
        line_index = newline_indexes.find_index { |index| scan.charpos <= index }
        line_index ||= newline_indexes.size

        line_start_char_index = if line_index == 0
                                  0
                                else
                                  newline_indexes[line_index - 1]
                                end

        char_index = scan.charpos - line_start_char_index

        yield scan, line_index, char_index
      end
    end

    if Gem::Version.new(Haml::VERSION) >= Gem::Version.new('5')
      # Same as Haml::Util.handle_interpolation, but enables multiline mode on the regex
      def handle_interpolation_with_newline(str)
        scan = StringScanner.new(str)
        yield scan while scan.scan(/(.*?)(\\*)#([{@$])/m)
        scan.rest
      end
    else
      # Same as Haml::Util.handle_interpolation, but enables multiline mode on the regex
      def handle_interpolation_with_newline(str)
        scan = StringScanner.new(str)
        yield scan while scan.scan(/(.*?)(\\*)\#\{/m)
        scan.rest
      end
    end

    # Returns indexes of all occurrences of a substring within a string.
    #
    # Note, this will not return overlapping substrings, so searching for "aa"
    # in "aaa" will only find one substring, not two.
    #
    # @param text [String] the text to search
    # @param substr [String] the substring to search for
    # @return [Array<Integer>] list of indexes where the substring occurs
    def extract_substring_positions(text, substr)
      positions = []
      scanner = StringScanner.new(text)
      positions << scanner.charpos while scanner.scan(/(.*?)#{substr}/)
      positions
    end

    # Converts a string containing underscores/hyphens/spaces into CamelCase.
    #
    # @param str [String]
    # @return [String]
    def camel_case(str)
      str.split(/_|-| /).map { |part| part.sub(/^\w/, &:upcase) }.join
    end

    # Find all consecutive items satisfying the given block of a minimum size,
    # yielding each group of consecutive items to the provided block.
    #
    # @param items [Array]
    # @param satisfies [Proc] function that takes an item and returns true/false
    # @param min_consecutive [Fixnum] minimum number of consecutive items before
    #   yielding the group
    # @yield Passes list of consecutive items all matching the criteria defined
    #   by the `satisfies` {Proc} to the provided block
    # @yieldparam group [Array] List of consecutive items
    # @yieldreturn [Boolean] block should return whether item matches criteria
    #   for inclusion
    def for_consecutive_items(items, satisfies, min_consecutive = 2)
      current_index = -1

      while (current_index += 1) < items.count
        next unless satisfies[items[current_index]]

        count = count_consecutive(items, current_index, &satisfies)
        next unless count >= min_consecutive

        # Yield the chunk of consecutive items
        yield items[current_index...(current_index + count)]

        current_index += count # Skip this patch of consecutive items to find more
      end
    end

    # Count the number of consecutive items satisfying the given {Proc}.
    #
    # @param items [Array]
    # @param offset [Fixnum] index to start searching from
    # @yield [item] Passes item to the provided block.
    # @yieldparam item [Object] Item to evaluate as matching criteria for
    #   inclusion
    # @yieldreturn [Boolean] whether to include the item
    # @return [Integer]
    def count_consecutive(items, offset = 0)
      count = 1
      count += 1 while (offset + count < items.count) && yield(items[offset + count])
      count
    end

    # Process ERB, providing some values for for versions to it
    #
    # @param content [String] the (usually yaml) content to process
    # @return [String]
    def process_erb(content)
      # Variables for use in the ERB's post-processing
      rubocop_version = HamlLint::VersionComparer.for_rubocop

      ERB.new(content).result(binding)
    end

    def insert_after_indentation(code, insert)
      index = code.index(/\S/)
      "#{code[0...index]}#{insert}#{code[index..]}"
    end

    # Calls a block of code with a modified set of environment variables,
    # restoring them once the code has executed.
    #
    # @param env [Hash] environment variables to set
    def with_environment(env)
      old_env = {}
      env.each do |var, value|
        old_env[var] = ENV[var.to_s]
        ENV[var.to_s] = value
      end

      yield
    ensure
      old_env.each { |var, value| ENV[var.to_s] = value }
    end

    def indent(string, nb_indent)
      if nb_indent < 0
        string.gsub(/^ {1,#{-nb_indent}}/, '')
      else
        string.gsub(/^/, ' ' * nb_indent)
      end
    end

    def map_subset!(array, range, &block)
      subset = array[range]
      return if subset.nil? || subset.empty?

      array[range] = subset.map(&block)
    end

    def map_after_first!(array, &block)
      map_subset!(array, 1..-1, &block)
    end

    # Returns true if line is only whitespace.
    # Note, this is not like blank? is rails. For nil, this returns false.
    def is_blank_line?(line)
      line && line.index(/\S/).nil?
    end

    def check_error_when_compiling_haml(haml_string)
      begin
        ruby_code = ::HamlLint::Adapter.detect_class.new(haml_string).precompile
      rescue StandardError => e
        return e
      end
      eval("BEGIN {return nil}; #{ruby_code}", binding, __FILE__, __LINE__) # rubocop:disable Security/Eval
      # The eval will return nil
    rescue ::SyntaxError
      $!
    end

    def regexp_for_parts(parts, join_regexp, prefix: nil, suffix: nil)
      regexp_code = parts.map { |c| Regexp.quote(c) }.join(join_regexp)
      regexp_code = "#{prefix}#{regexp_code}#{suffix}"
      Regexp.new(regexp_code)
    end
  end
end
