module HamlLint
  # Utility class for extracting Ruby script from a HAML file that can then be
  # linted with a Ruby linter (i.e. is "legal" Ruby). The goal is to turn this:
  #
  #     - if signed_in?(viewer)
  #       %span Stuff
  #       = link_to 'Sign Out', sign_out_path
  #     - else
  #       .some-class{ class: my_method }= my_method
  #       = link_to 'Sign In', sign_in_path
  #
  # into this:
  #
  #     if signed_in?(viewer)
  #       link_to 'Sign Out', sign_out_path
  #     else
  #       { class: my_method }
  #       my_method
  #       link_to 'Sign In', sign_in_path
  #     end
  #
  class ScriptExtractor
    include HamlVisitor

    attr_reader :source, :source_map

    def initialize(parser)
      @parser = parser
    end

    def extract
      visit(@parser.tree)
      @source = @code.join("\n")
    end

  protected

    def visit_root(node)
      @code = []
      @source_map = {}
      @indent_level = 0

      yield # Collect lines of code from children
    end

    def visit_tag(node)
      additional_attributes = node.value[:attributes_hashes]

      # Include dummy references to code executed in attributes list
      # (this forces a "use" of a variable to prevent "assigned but unused
      # variable" lints)
      additional_attributes.each do |attributes_code|
        # Normalize by removing excess whitespace to avoid format lints
        attributes_code = attributes_code.gsub(/\s*\n\s*/, ' ').strip

        # Attributes can either be a method call or a literal hash, so wrap it
        # in a method call itself in order to avoid having to differentiate the
        # two.
        add_line("{}.merge(#{attributes_code})", node)
      end

      code = node.value[:value].to_s.strip
      add_line(code, node) if node.value[:parse]
    end

    def visit_script(node)
      code = node.value[:text].to_s
      add_line(code.strip, node)

      start_block = anonymous_block?(code) || start_block_keyword?(code)

      if start_block
        @indent_level += 1
      end

      yield # Continue extracting code from children

      if start_block
        @indent_level -= 1
        add_line('end', node)
      end
    end

    def visit_silent_script(node, &block)
      visit_script(node, &block)
    end

    def visit_filter(node)
      if node.value[:name] == 'ruby'
        node.value[:text].split("\n").each_with_index do |line, index|
          add_line(line, node.line + index + 1)
        end
      else
        extract_interpolated_values(node.value[:text]) do |interpolated_code|
          add_line(interpolated_code, node)
        end
      end
    end

  private

    def add_line(code, node_or_line)
      unless code.empty?
        # Since mid-block keywords are children of the corresponding start block
        # keyword, we need to reduce their indentation level by 1
        indent_level = @indent_level + (mid_block_keyword?(code) ? -1 : 0)
        indent = ('  ' * indent_level)

        @code << indent + code
        @source_map[@code.count] =
          if node_or_line.is_a?(Fixnum)
            node_or_line
          else
            node_or_line.line
          end
      end
    end

    def anonymous_block?(text)
      !!(text =~ /do\s*(?:\|\s*[^\|]*\s*\|)?\z/)
    end

    START_BLOCK_KEYWORDS = %w[if unless case begin for while]
    def start_block_keyword?(text)
      START_BLOCK_KEYWORDS.include?(block_keyword(text))
    end

    MID_BLOCK_KEYWORDS = %w[else elsif when rescue ensure]
    def mid_block_keyword?(text)
      MID_BLOCK_KEYWORDS.include?(block_keyword(text))
    end

    def block_keyword(text)
      # Need to handle 'for'/'while' since regex stolen from HAML parser doesn't
      if keyword = text.scan(/\s*([^\s]+)\s+/)[0]
        return keyword[0] if %w[for while].include?(keyword[0])
      end

      return unless keyword = text.scan(Haml::Parser::BLOCK_KEYWORD_REGEX)[0]
      keyword[0] || keyword[1]
    end

    # Yields interpolated values within a block of filter text.
    def extract_interpolated_values(filter_text)
      Haml::Util.handle_interpolation(filter_text.dump) do |scan|
        escape_count = (scan[2].size - 1) / 2
        scan.matched[0...-3 - escape_count]
        if escape_count.even?
          yield Haml::Util.balance(scan, '{', '}', 1)[0][0...-1]
        end
      end
    end
  end
end
