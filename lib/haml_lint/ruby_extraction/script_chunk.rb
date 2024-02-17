# frozen_string_literal: true

require 'ripper'

module HamlLint::RubyExtraction
  # Chunk for handling outputting and silent scripts, so `  = foo` and `  - bar`
  # Does NOT handle a script beside a tag (ex: `%div= spam`)
  class ScriptChunk < BaseChunk
    MID_BLOCK_KEYWORDS = %w[else elsif when rescue ensure].freeze

    # @return [String] The prefix for the first outputting string of this script. (One of = != &=)
    #   The outputting scripts after the first are always with =
    attr_reader :first_output_haml_prefix

    # @return [Boolean] true if this ScriptChunk must be at the beginning of a chunk.
    #   This blocks this ScriptChunk from being fused to a ScriptChunk that is before it.
    #   Needed to handle some patterns of outputting script.
    attr_reader :must_start_chunk

    # @return [Array<Integer>] Line indexes to ignore when building the source_map. For examples,
    #   implicit `end` are on their own line in the Ruby file, but in the HAML, they are absent.
    attr_reader :skip_line_indexes_in_source_map

    # @return [HamlLint::RubyExtraction::BaseChunk] The previous chunk can affect how
    #   our starting marker must be indented.
    attr_reader :previous_chunk

    def initialize(*args, previous_chunk:, must_start_chunk: false, # rubocop:disable Metrics/ParameterLists
                   skip_line_indexes_in_source_map: [], first_output_haml_prefix: '=', **kwargs)
      super(*args, **kwargs)
      @must_start_chunk = must_start_chunk
      @skip_line_indexes_in_source_map = skip_line_indexes_in_source_map
      @previous_chunk = previous_chunk
      @first_output_haml_prefix = first_output_haml_prefix
    end

    def fuse(following_chunk)
      case following_chunk
      when ScriptChunk
        fuse_script_chunk(following_chunk)
      when ImplicitEndChunk
        fuse_implicit_end(following_chunk)
      end
    end

    def fuse_script_chunk(following_chunk)
      return if following_chunk.end_marker_indent.nil?
      return if following_chunk.must_start_chunk

      nb_blank_lines_between = following_chunk.haml_line_index - haml_line_index - nb_haml_lines
      blank_lines = nb_blank_lines_between > 0 ? [''] * nb_blank_lines_between : []
      new_lines = @ruby_lines + blank_lines + following_chunk.ruby_lines

      source_map_skips = @skip_line_indexes_in_source_map
      source_map_skips.concat(following_chunk.skip_line_indexes_in_source_map
                                .map { |i| i + @ruby_lines.size })

      ScriptChunk.new(node,
                      new_lines,
                      haml_line_index: haml_line_index,
                      skip_line_indexes_in_source_map: source_map_skips,
                      end_marker_indent: following_chunk.end_marker_indent,
                      previous_chunk: previous_chunk,
                      first_output_haml_prefix: @first_output_haml_prefix)
    end

    def fuse_implicit_end(following_chunk)
      new_lines = @ruby_lines.dup
      last_non_empty_line_index = new_lines.rindex { |line| line =~ /\S/ }

      # There is only one line in ImplicitEndChunk
      new_end_index = last_non_empty_line_index + 1
      new_lines.insert(new_end_index, following_chunk.ruby_lines.first)
      source_map_skips = @skip_line_indexes_in_source_map + [new_end_index]

      ScriptChunk.new(node,
                      new_lines,
                      haml_line_index: haml_line_index,
                      skip_line_indexes_in_source_map: source_map_skips,
                      end_marker_indent: following_chunk.end_marker_indent,
                      previous_chunk: previous_chunk,
                      first_output_haml_prefix: @first_output_haml_prefix)
    end

    def start_marker_indent
      default_indent = super
      default_indent += 2 if MID_BLOCK_KEYWORDS.include?(ChunkExtractor.block_keyword(ruby_lines.first))
      [default_indent, previous_chunk&.end_marker_indent || previous_chunk&.start_marker_indent].compact.max
    end

    def transfer_correction_logic(coordinator, to_ruby_lines, haml_lines)
      to_haml_lines = self.class.format_ruby_lines_to_haml_lines(
        to_ruby_lines,
        script_output_ruby_prefix: coordinator.script_output_prefix,
        first_output_haml_prefix: @first_output_haml_prefix
      )

      haml_lines[@haml_line_index..haml_end_line_index] = to_haml_lines
    end

    ALLOW_EXPRESSION_AFTER_LINE_ENDING_WITH = %w[else begin ensure].freeze

    def self.format_ruby_lines_to_haml_lines(to_ruby_lines, script_output_ruby_prefix:, first_output_haml_prefix: '=') # rubocop:disable Metrics
      to_ruby_lines.reject! { |l| l.strip == 'end' }
      return [] if to_ruby_lines.empty?

      statement_start_line_indexes = find_statement_start_line_indexes(to_ruby_lines)

      continued_line_indent_delta = 2
      continued_line_min_indent = 2

      cur_line_start_index = nil
      line_start_indexes_that_need_pipes = []
      haml_output_prefix = first_output_haml_prefix
      to_haml_lines = to_ruby_lines.map.with_index do |line, i| # rubocop:disable Metrics/BlockLength
        if !/\S/.match?(line)
          # whitespace or empty lines, we don't want any indentation
          ''
        elsif statement_start_line_indexes.include?(i)
          cur_line_start_index = i
          code_start = line.index(/\S/)
          continued_line_min_indent = code_start + 2
          if line[code_start..].start_with?(script_output_ruby_prefix)
            line = line.sub(script_output_ruby_prefix, '')
            # The next lines may have been too indented because of the "HL.out = " prefix
            continued_line_indent_delta = 2 - script_output_ruby_prefix.size
            new_line = "#{line[0...code_start]}#{haml_output_prefix} #{line[code_start..]}"
            haml_output_prefix = '='
            new_line
          else
            continued_line_indent_delta = 2
            "#{line[0...code_start]}- #{line[code_start..]}"
          end
        else
          unless to_ruby_lines[i - 1].end_with?(',')
            line_start_indexes_that_need_pipes << cur_line_start_index
          end

          line = HamlLint::Utils.indent(line, continued_line_indent_delta)
          cur_indent = line[/^ */].size
          if cur_indent < continued_line_min_indent
            line = HamlLint::Utils.indent(line, continued_line_min_indent - cur_indent)
          end
          line
        end
      end

      # Starting from the end because we need to add newlines when 2 groups of lines need pipes, so that they are
      # separate.
      line_start_indexes_that_need_pipes.reverse_each do |cur_line_i|
        loop do
          cur_line = to_haml_lines[cur_line_i]
          break if cur_line.nil? || cur_line.empty?
          to_haml_lines[cur_line_i] = cur_line + ' |'
          cur_line_i += 1

          break if statement_start_line_indexes.include?(cur_line_i)
        end

        next_line = to_haml_lines[cur_line_i]
        if next_line && HamlLint::RubyExtraction::ChunkExtractor::HAML_PARSER_INSTANCE.send(:is_multiline?, next_line)
          to_haml_lines.insert(cur_line_i, '')
        end
      end

      to_haml_lines
    end

    def self.find_statement_start_line_indexes(to_ruby_lines) # rubocop:disable Metrics
      if to_ruby_lines.size == 1
        if to_ruby_lines.first[/\S/]
          return [0]
        else
          return []
        end
      end
      statement_start_line_indexes = [] # 0-indexed
      allow_expression_after_line_number = 0 # 1-indexed
      last_do_keyword_line_number = nil # 1-indexed, like Ripper.lex

      to_ruby_string = to_ruby_lines.join("\n")
      if RUBY_VERSION < '3.1'
        # Ruby 2.6's Ripper has issues when it encounters a else, when, elsif without a matching if/case before.
        # It literally stop lexing at that point without any error.
        # Ex from 2.7.8:
        #   require 'ripper'
        #   Ripper.lex("a\nelse\nb")
        #   #=> [[[1, 0], :on_ident, "a", CMDARG], [[1, 1], :on_nl, "\n", BEG], [[2, 0], :on_kw, "else", BEG]]
        # So we add enough ifs to last quite a few layer. Hopefully enough for all needs. To clarify, there would need
        # as many "end" keyword in a single ScriptChunk followed by one of the problematic keyword for the problem
        # to show up.
        # Considering that a `end` without anything else on the line is removed from to_ruby_lines before getting here
        # (in format_ruby_lines_to_haml_lines), 10 ifs should be plenty.
        to_ruby_string = ('if a;' * 10) + to_ruby_string
      end

      last_line_number_seen = nil
      Ripper.lex(to_ruby_string).each do |start_loc, token, str|
        last_line_number_seen = start_loc[0]
        if token == :on_nl
          # :on_nl happens when we have a meaningful line change.
          allow_expression_after_line_number = start_loc[0]
          next
        elsif token == :on_ignored_nl
          # :on_ignored_nl happens for newlines within an expression, or consecutive newlines..
          #    and some cases we care about such as a newline after the pipes after arguments of a block
          if last_do_keyword_line_number == start_loc[0]
            # When starting a block, Ripper.lex gives :on_ignored_nl
            allow_expression_after_line_number = start_loc[0]
          end
          next
        end

        if allow_expression_after_line_number && str[/\S/]
          if allow_expression_after_line_number < start_loc[0]
            # Ripper.lex returns line numbers 1-indexed, we want 0-indexed
            statement_start_line_indexes << start_loc[0] - 1
          end
          allow_expression_after_line_number = nil
        end

        if token == :on_comment
          # :on_comment contain its own newline at the end of the content
          allow_expression_after_line_number = start_loc[0]
        elsif token == :on_kw
          if str == 'do'
            # Because of the possible arguments for the block, we can't simply set is_between_expressions to true
            last_do_keyword_line_number = start_loc[0]
          elsif ALLOW_EXPRESSION_AFTER_LINE_ENDING_WITH.include?(str)
            allow_expression_after_line_number = start_loc[0]
          end
        end
      end

      # number is 1-indexed, and we want the line after it, so that's great
      if last_line_number_seen < to_ruby_lines.size && to_ruby_lines[last_line_number_seen..].any? { |l| l[/\S/] }
        # There are non-empty lines after the last line Ripper showed us, that's a problem!
        msg = +'It seems Ripper did not properly process some source code. Please make sure you are on the '
        msg << 'latest Haml-Lint version, then create an issue at '
        msg << "https://github.com/sds/haml-lint/issues and include the following information:\n"
        msg << "Ruby version: #{RUBY_VERSION}\n"
        msg << "Haml-Lint version: #{HamlLint::VERSION}\n"
        msg << "HAML version: #{Haml::VERSION}\n"
        msg << "problematic source code:\n```\n#{to_ruby_lines.join("\n")}\n```"
        raise msg
      end

      statement_start_line_indexes
    end
  end
end
