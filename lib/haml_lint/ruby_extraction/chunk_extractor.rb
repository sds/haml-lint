# frozen_string_literal: true

# rubocop:disable Metrics
module HamlLint::RubyExtraction
  # Extracts "chunks" of the haml file into instances of subclasses of HamlLint::RubyExtraction::BaseChunk.
  #
  # This is the first step of generating Ruby code from a HAML file to then be processed by RuboCop.
  # See HamlLint::RubyExtraction::BaseChunk for more details.
  class ChunkExtractor
    include HamlLint::HamlVisitor

    attr_reader :script_output_prefix

    def initialize(document, script_output_prefix:)
      @document = document
      @script_output_prefix = script_output_prefix
    end

    def extract
      raise 'Already extracted' if @ruby_chunks

      @ruby_chunks = []
      @original_haml_lines = @document.source_lines

      visit(@document.tree)
      @ruby_chunks
    end

    def visit_root(_node)
      yield # Collect lines of code from children
    end

    # Visiting lines like `  Some raw text to output`
    def visit_plain(node)
      indent = @original_haml_lines[node.line - 1].index(/\S/)
      @ruby_chunks << PlaceholderMarkerChunk.new(node, 'plain', indent: indent)
    end

    # Visiting lines like `  -# Some commenting!`
    def visit_haml_comment(node)
      # We want to preserve leading whitespace if it exists, but add a leading
      # whitespace if it doesn't exist so that RuboCop's LeadingCommentSpace
      # doesn't complain
      line_index = node.line - 1
      lines = @original_haml_lines[line_index..(line_index + node.text.count("\n"))].dup
      indent = lines.first.index(/\S/)
      # Remove only the -, the # will align with regular code
      #  -# comment
      #  - foo()
      # becomes
      #  # comment
      #  foo()
      lines[0] = lines[0].sub('-', '')

      # Adding a space before the comment if its missing
      # We can't fix those, so make sure not to generate warnings for them.
      lines[0] = lines[0].sub(/\A(\s*)#(\S)/, '\\1# \\2')

      HamlLint::Utils.map_after_first!(lines) do |line|
        # Since the indent/spaces of the extra line comments isn't exactly in the haml,
        # it's not RuboCop's job to fix indentation, so just make a reasonable indentation
        # to avoid offenses.
        ' ' * indent + line.sub(/^\s*/, '# ').rstrip
      end

      # Using Placeholder instead of script because we can't revert back to the
      # exact original comment since multiple syntax lead to the exact same comment.
      @ruby_chunks << HamlCommentChunk.new(node, lines, end_marker_indent: indent)
    end

    # Visiting comments which are output to HTML. Lines looking like
    #   `  / This will be in the HTML source!`
    def visit_comment(node)
      lines = raw_lines_of_interest(node.line - 1)
      indent = lines.first.index(/\S/)
      @ruby_chunks << PlaceholderMarkerChunk.new(node, 'comment', indent: indent)
    end

    # Visit a script which outputs. Lines looking like `  = foo`
    def visit_script(node, &block)
      lines = raw_lines_of_interest(node.line - 1)

      if lines.first !~ /\A\s*[-=]/
        # The line doesn't start with a - or a =, this is actually a "plain"
        # that contains interpolation.
        indent = lines.first.index(/\S/)
        @ruby_chunks << PlaceholderMarkerChunk.new(node, 'interpolation', indent: indent)
        add_interpolation_chunks(node, lines.first, node.line - 1, indent: indent)
        return
      end

      lines[0] = lines[0].sub(/(=[ \t]?)/, '')
      line_indentation = Regexp.last_match(1).size

      raw_code = lines.join("\n")

      if lines[0][/\S/] == '#'
        # a script that only constains a comment... needs special handling
        comment_index = lines[0].index(/\S/)
        lines[0].insert(comment_index + 1, " #{script_output_prefix.rstrip}")
      else
        lines[0] = HamlLint::Utils.insert_after_indentation(lines[0], script_output_prefix)
      end

      indent_delta = script_output_prefix.size - line_indentation
      HamlLint::Utils.map_after_first!(lines) do |line|
        HamlLint::Utils.indent(line, indent_delta)
      end

      prev_chunk = @ruby_chunks.last
      if prev_chunk.is_a?(ScriptChunk) &&
          prev_chunk.node.type == :script &&
          prev_chunk.node == node.parent
        # When an outputting script is nested under another outputting script,
        # we want to block them from being merged together by rubocop, because
        # this doesn't make sense in HAML.
        # Example:
        #   = if this_is_short
        #     = this_is_short_too
        # Could become (after RuboCop):
        #   HL.out = (HL.out = this_is_short_too if this_is_short)
        # Or in (broken) HAML style:
        #   = this_is_short_too = if this_is_short
        # By forcing this to start a chunk, there will be extra placeholders which
        # blocks rubocop from merging the lines.
        must_start_chunk = true
      end

      finish_visit_any_script(node, lines, raw_code: raw_code, must_start_chunk: must_start_chunk, &block)
    end

    # Visit a script which doesn't output. Lines looking like `  - foo`
    def visit_silent_script(node, &block)
      lines = raw_lines_of_interest(node.line - 1)
      lines[0] = lines[0].sub(/(-[ \t]?)/, '')
      nb_to_deindent = Regexp.last_match(1).size

      HamlLint::Utils.map_after_first!(lines) do |line|
        line.sub(/^ {1,#{nb_to_deindent}}/, '')
      end

      finish_visit_any_script(node, lines, &block)
    end

    # Code common to both silent and outputting scripts
    #
    # raw_code is the code before we do transformations, such as adding the `HL.out = `
    def finish_visit_any_script(node, lines, raw_code: nil, must_start_chunk: false)
      raw_code ||= lines.join("\n")
      start_nesting = self.class.start_nesting_after?(raw_code)

      lines = add_following_empty_lines(node, lines)

      my_indent = lines.first.index(/\S/)
      indent_after = indent_after_line_index(node.line - 1 + lines.size - 1) || 0
      indent_after = [my_indent, indent_after].max

      @ruby_chunks << ScriptChunk.new(node, lines,
                                      end_marker_indent: indent_after,
                                      must_start_chunk: must_start_chunk,
                                      previous_chunk: @ruby_chunks.last)

      yield

      if start_nesting
        if node.children.empty?
          raise "Line #{node.line} should be followed by indentation. This might actually" \
                " work in Haml, but it's almost a bug that it does. haml-lint cannot process."
        end

        last_child = node.children.last
        if last_child.is_a?(HamlLint::Tree::SilentScriptNode) && last_child.keyword == 'end'
          # This is allowed in Haml 5, gotta handle it!
          # No need for the implicit end chunk since there is an explicit one
        else
          @ruby_chunks << ImplicitEndChunk.new(node, [' ' * my_indent + 'end'],
                                               haml_line_index: @ruby_chunks.last.haml_end_line_index,
                                               end_marker_indent: my_indent)
        end
      end
    end

    # Visiting a tag. Lines looking like `  %div`
    def visit_tag(node)
      indent = @original_haml_lines[node.line - 1].index(/\S/)

      has_children = !node.children.empty?
      if has_children
        # We don't want to use a block because assignments in a block are local to that block,
        # so the semantics of the extracted ruby would be different from the one generated by
        # Haml. Those differences can make some cops, such as UselessAssignment, have false
        # positives
        code = 'begin'
        @ruby_chunks << AdHocChunk.new(node,
                                       [' ' * indent + code])
        indent += 2
      end

      @ruby_chunks << PlaceholderMarkerChunk.new(node, 'tag', indent: indent)

      current_line_index = visit_tag_attributes(node, indent: indent)
      visit_tag_script(node, line_index: current_line_index, indent: indent)

      if has_children
        yield
        indent -= 2
        @ruby_chunks << AdHocChunk.new(node,
                                       [' ' * indent + 'ensure', ' ' * indent + '  HL.noop', ' ' * indent + 'end'],
                                       haml_line_index: @ruby_chunks.last.haml_end_line_index)
      end
    end

    # (Called manually form visit_tag)
    # Visiting the attributes of a tag. Lots of different examples below in the code.
    # A common syntax is: `%div{style: 'yes_please'}`
    #
    # Returns the new line_index we reached, useful to handle the script that follows
    def visit_tag_attributes(node, indent:)
      final_line_index = node.line - 1
      additional_attributes = node.dynamic_attributes_sources

      attributes_code = additional_attributes.first
      if !attributes_code && node.hash_attributes? && node.dynamic_attributes_sources.empty?
        # No idea why .foo{:bar => 123} doesn't get here, but .foo{:bar => '123'} does...
        # The code we get for the later is {:bar => '123'}.
        # We normalize it by removing the { } so that it matches wha we normally get
        attributes_code = node.dynamic_attributes_source[:hash][1...-1]
      end

      return final_line_index unless attributes_code
      # Attributes have different ways to be given to us:
      #   .foo{bar: 123} => "bar: 123"
      #   .foo{:bar => 123} => ":bar => 123"
      #   .foo{:bar => '123'} => "{:bar => '123'}" # No idea why this is different
      #   .foo(bar = 123) => '{"bar" => 123,}'
      #   .foo{html_attrs('fr-fr')} => html_attrs('fr-fr')
      #
      # The (bar = 123) case is extra painful to autocorrect (so is ignored).
      # #raw_ruby_from_haml  will "detect" this case by not finding the code.
      #
      # We wrap the result in a method to have a valid syntax for all 3 ways
      # without having to differentiate them.
      first_line_offset, raw_attributes_lines = raw_ruby_lines_from_haml(attributes_code,
                                                                         node.line - 1)

      return final_line_index unless raw_attributes_lines

      final_line_index += raw_attributes_lines.size - 1

      # Since .foo{bar: 123} => "bar: 123" needs wrapping (Or it would be a syntax error) and
      # .foo{html_attrs('fr-fr')} => html_attrs('fr-fr') doesn't care about being
      # wrapped, we always wrap to place them to a similar offset to how they are in the haml.
      wrap_by = first_line_offset - indent
      if wrap_by < 2
        # Need 2 minimum, for "W(". If we have less, we must indent everything for the difference
        extra_indent = 2 - wrap_by
        HamlLint::Utils.map_after_first!(raw_attributes_lines) do |line|
          HamlLint::Utils.indent(line, extra_indent)
        end
        wrap_by = 2
      end
      raw_attributes_lines = wrap_lines(raw_attributes_lines, wrap_by)
      raw_attributes_lines[0] = ' ' * indent + raw_attributes_lines[0]

      @ruby_chunks << TagAttributesChunk.new(node, raw_attributes_lines,
                                             end_marker_indent: indent,
                                             indent_to_remove: extra_indent)

      final_line_index
    end

    # Visiting the script besides tag. The part to the right of the equal sign of
    # lines looking like `  %div= foo(bar)`
    def visit_tag_script(node, line_index:, indent:)
      return if node.script.nil? || node.script.empty?
      # We ignore scripts which are just a comment
      return if node.script[/\S/] == '#'

      first_line_offset, script_lines = raw_ruby_lines_from_haml(node.script, line_index)

      if script_lines.nil?
        # This is a string with interpolation after a tag
        # ex: %tag hello #{world}
        # Sadly, the text with interpolation is escaped from the original, but this code
        # needs the original.
        interpolation_original = @document.unescape_interpolation_to_original_cache[node.script]

        line_start_index = @original_haml_lines[node.line - 1].rindex(interpolation_original)
        add_interpolation_chunks(node, interpolation_original, node.line - 1,
                                 line_start_index: line_start_index, indent: indent)
      else
        script_lines[0] = "#{' ' * indent}#{script_output_prefix}#{script_lines[0]}"
        indent_delta = script_output_prefix.size - first_line_offset + indent
        HamlLint::Utils.map_after_first!(script_lines) do |line|
          HamlLint::Utils.indent(line, indent_delta)
        end

        @ruby_chunks << TagScriptChunk.new(node, script_lines,
                                           haml_line_index: line_index,
                                           end_marker_indent: indent)
      end
    end

    # Visiting a HAML filter. Lines looking like `  :javascript` and the following lines
    # that are nested.
    def visit_filter(node)
      # For unknown reasons, haml doesn't escape interpolations in filters.
      # So we can rely on \n to split / get the number of lines.
      filter_name_indent = @original_haml_lines[node.line - 1].index(/\S/)
      if node.filter_type == 'ruby'
        # The indentation in node.text is normalized, so that at least one line
        # is indented by 0.
        lines = node.text.split("\n")
        lines.map! do |line|
          if line !~ /\S/
            # whitespace or empty
            ''
          else
            ' ' * filter_name_indent + line
          end
        end

        @ruby_chunks << RubyFilterChunk.new(node, lines,
                                            haml_line_index: node.line, # it's one the next line, no need for -1
                                            start_marker_indent: filter_name_indent,
                                            end_marker_indent: filter_name_indent)
      elsif node.text.include?('#')
        name_indentation = ' ' * @original_haml_lines[node.line - 1].index(/\S/)
        # TODO: HAML_LINT_FILTER could be in the string and mess things up
        lines = ["#{name_indentation}#{script_output_prefix}<<~HAML_LINT_FILTER"]
        lines.concat @original_haml_lines[node.line..(node.line + node.text.count("\n") - 1)]
        lines << "#{name_indentation}HAML_LINT_FILTER"
        @ruby_chunks << NonRubyFilterChunk.new(node, lines,
                                               end_marker_indent: filter_name_indent)
      # Those could be interpolation. We treat them as a here-doc, which is nice since we can
      # keep the indentation as-is.
      else
        @ruby_chunks << PlaceholderMarkerChunk.new(node, 'filter', indent: filter_name_indent,
                                                   nb_lines: 1 + node.text.count("\n"))
      end
    end

    # Adds chunks for the interpolation within the given code
    def add_interpolation_chunks(node, code, haml_line_index, indent:, line_start_index: 0)
      HamlLint::Utils.handle_interpolation_with_indexes(code) do |scanner, line_index, char_index|
        escapes = scanner[2].size
        next if escapes.odd?
        char = scanner[3] # '{', '@' or '$'
        if Gem::Version.new(Haml::VERSION) >= Gem::Version.new('5') && (char != '{')
          # Before Haml 5, scanner didn't have a scanner[3], it only handled `#{}`
          next
        end

        start_char_index = char_index
        start_char_index += line_start_index if line_index == 0

        Haml::Util.balance(scanner, '{', '}', 1)[0][0...-1]

        # Need to manually get the code now that we have positions so that all whitespace is present,
        # because Haml::Util.balance does a strip...
        interpolated_code = code[char_index...scanner.charpos - 1]

        interpolated_code = "#{' ' * indent}#{script_output_prefix}#{interpolated_code}"

        if interpolated_code.include?("\n")
          # We can't correct multiline interpolation.
          # Finding meaningful code to generate and then transfer back is pretty complex
          placeholder_code = interpolated_code.gsub(/\s*\n\s*/, ' ').rstrip
          unless parse_ruby(placeholder_code)
            placeholder_code = interpolated_code.gsub(/\s*\n\s*/, '; ').rstrip
          end
          @ruby_chunks << AdHocChunk.new(node, [placeholder_code],
                                         haml_line_index: haml_line_index + line_index)
        else
          @ruby_chunks << InterpolationChunk.new(node, [interpolated_code],
                                                 haml_line_index: haml_line_index + line_index,
                                                 start_char_index: start_char_index,
                                                 end_marker_indent: indent)
        end
      end
    end

    # Returns the raw lines from the haml for the given index.
    # Multiple lines are returned when a line ends with a comma as that is the only
    # time HAMLs allows Ruby lines to be split.
    def raw_lines_of_interest(first_line_index)
      line_index = first_line_index
      lines_of_interest = [@original_haml_lines[line_index]]

      while @original_haml_lines[line_index].rstrip.end_with?(',')
        line_index += 1
        lines_of_interest << @original_haml_lines[line_index]
      end

      lines_of_interest
    end

    # Haml's line-splitting rules (allowed after comma in scripts and attributes) are handled
    # at the parser level, so Haml doesn't provide the code as it is actually formatted in the Haml
    # file. #raw_ruby_from_haml extracts the ruby code as it is exactly in the Haml file.
    # The first and last lines may not be the complete lines from the Haml, only the Ruby parts
    # and the indentation between the first and last list.
    def raw_ruby_lines_from_haml(code, first_line_index)
      stripped_code = code.strip
      return if stripped_code.empty?

      lines_of_interest = raw_lines_of_interest(first_line_index)

      if lines_of_interest.size == 1
        index = lines_of_interest.first.index(stripped_code)
        if lines_of_interest.first.include?(stripped_code)
          return [index, [stripped_code]]
        else
          # Sometimes, the code just isn't in the Haml when Haml does transformations to it
          return
        end
      end

      raw_haml = lines_of_interest.join("\n")

      # Need the gsub because while multiline scripts are turned into a single line,
      # by haml, multiline tag attributes are not.
      code_parts = stripped_code.gsub("\n", ' ').split(/,\s*/)

      regexp_code = code_parts.map { |c| Regexp.quote(c) }.join(',\\s*')
      regexp = Regexp.new(regexp_code)

      match = raw_haml.match(regexp)

      raw_ruby = match[0]
      ruby_lines = raw_ruby.split("\n")
      first_line_offset = match.begin(0)

      [first_line_offset, ruby_lines]
    end

    def wrap_lines(lines, wrap_depth)
      lines = lines.dup
      wrapping_prefix = 'W' * (wrap_depth - 1) + '('
      lines[0] = wrapping_prefix + lines[0]
      lines[-1] = lines[-1] + ')'
      lines
    end

    # Adds empty lines that follow the lines (Used for scripts), so that
    # RuboCop can receive them too. Some cops are sensitive to empty lines.
    def add_following_empty_lines(node, lines)
      first_line_index = node.line - 1 + lines.size
      extra_lines = []

      extra_lines << '' while HamlLint::Utils.is_blank_line?(@original_haml_lines[first_line_index + extra_lines.size])

      if @original_haml_lines[first_line_index + extra_lines.size].nil?
        # Since we reached the end of the document without finding content,
        # then we don't add those lines.
        return lines
      end

      lines + extra_lines
    end

    def parse_ruby(source)
      @ruby_parser ||= HamlLint::RubyParser.new
      @ruby_parser.parse(source)
    end

    def indent_after_line_index(line_index)
      (line_index + 1..@original_haml_lines.size - 1).each do |i|
        indent = @original_haml_lines[i].index(/\S/)
        return indent if indent
      end
      nil
    end

    def self.start_nesting_after?(code)
      anonymous_block?(code) || start_block_keyword?(code)
    end

    def self.anonymous_block?(code)
      # Don't start with a comment and end with a `do`
      # Definetly not perfect for the comment handling, but otherwise a more advanced parsing system is needed.
      # Move the comment to its own line if it's annoying.
      code !~ /\A\s*#/ &&
        code =~ /\bdo\s*(\|[^|]*\|\s*)?(#.*)?\z/
    end

    START_BLOCK_KEYWORDS = %w[if unless case begin for until while].freeze
    def self.start_block_keyword?(code)
      START_BLOCK_KEYWORDS.include?(block_keyword(code))
    end

    LOOP_KEYWORDS = %w[for until while].freeze
    def self.block_keyword(code)
      # Need to handle 'for'/'while' since regex stolen from HAML parser doesn't
      if (keyword = code[/\A\s*([^\s]+)\s+/, 1]) && LOOP_KEYWORDS.include?(keyword)
        return keyword
      end

      return unless keyword = code.scan(Haml::Parser::BLOCK_KEYWORD_REGEX)[0]
      keyword[0] || keyword[1]
    end
  end
end

# rubocop:enable Metrics
