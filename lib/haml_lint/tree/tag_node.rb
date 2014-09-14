module HamlLint::Tree
  # Represents a tag node in a HAML document.
  class TagNode < Node
    # Computed set of attribute hashes code.
    #
    # This is intended to be used by the `ScriptExtractor` only.
    def attributes_hashes
      @value[:attributes_hashes]
    end

    # Returns whether this tag contains executable script (e.g. is followed by a
    # `=`).
    #
    # @return [true,false]
    def contains_script?
      @value[:parse] && !@value[:value].strip.empty?
    end

    # List of classes statically defined for this tag.
    #
    # @example For `%tag.button.button-info{ class: status }`, this returns:
    #   ['button', 'button-info']
    #
    # @return [Array<String>] list of statically defined classes with leading
    #   dot removed
    def static_classes
      @static_classes ||=
        begin
          static_attributes_source.scan(/\.([-:\w]+)/)
        end
    end

    # List of ids statically defined for this tag.
    #
    # @example For `%tag.button#start-button{ id: special_id }`, this returns:
    #   ['start-button']
    #
    # @return [Array<String>] list of statically defined ids with leading `#`
    #   removed
    def static_ids
      @static_ids ||=
        begin
          static_attributes_source.scan(/#([-:\w]+)/)
        end
    end

    # Static element attributes defined after the tag name.
    #
    # @example For `%tag.button#start-button`, this returns:
    #   '.button#start-button'
    #
    # @return [String]
    def static_attributes_source
      @static_attributes_source ||=
        first_line_source[/\s*(%[-:\w]+)?((\.|#)[^{( $]+)/, 2] || ''
    end

    # Returns the source code for the dynamic attributes defined in `{...}`,
    # `(...)`, or `[...]` after a tag name.
    #
    # @example For `%tag.class{ id: 'hello' }(lang=en)`, this returns:
    #   { :hash => " id: 'hello' ", :html => "lang=en" }
    #
    # @return [Hash]
    def dynamic_attributes_source # rubocop:disable CyclomaticComplexity, MethodLength
      @dynamic_attributes_source ||=
        begin
          _tag_name, _static_attrs, rest = first_line_source
            .scan(/%([-:\w]+)([-:\w\.\#]*)(.*)/)[0]

          dynamic_attributes = {}
          hash_attributes = html_attributes = object_reference = nil

          while rest
            case rest[0]
            when '{'
              break if hash_attributes
              hash_attributes, rest = Haml::Util.balance(rest, '{', '}')
              dynamic_attributes[:hash] = hash_attributes
            when '('
              break if html_attributes
              html_attributes, rest = Haml::Util.balance(rest, '(', ')')
              dynamic_attributes[:html] = html_attributes
            when '['
              break if object_reference
              object_reference, rest = Haml::Util.balance(rest, '[', ']')
              dynamic_attributes[:object_ref] = object_reference
            else
              break
            end
          end

          dynamic_attributes
        end
    end

    # Whether this tag node has a set of hash attributes defined via the
    # curly brace syntax (e.g. `%tag{ lang: 'en' }`).
    #
    # @return [true,false]
    def hash_attributes?
      !dynamic_attributes_source[:hash].nil?
    end

    # Attributes defined after the tag name in Ruby hash brackets (`{}`).
    #
    # @example For `%tag.class{ lang: 'en' }`, this returns:
    #   " lang: 'en' "
    #
    # @return [String] source without the surrounding curly braces
    def hash_attributes_source
      dynamic_attributes_source[:hash]
    end

    # Whether this tag node has a set of HTML attributes defined via the
    # parentheses syntax (e.g. `%tag(lang=en)`).
    #
    # @return [true,false]
    def html_attributes?
      !dynamic_attributes_source[:html].nil?
    end

    # Attributes defined after the tag name in parentheses (`()`).
    #
    # @example For `%tag.class(lang=en)`, this returns:
    #   "lang=en"
    #
    # @return [String] source without the surrounding parentheses
    def html_attributes_source
      dynamic_attributes_source[:html] || ''
    end

    # Name of the HTML tag.
    #
    # @return [String]
    def tag_name
      @value[:name]
    end

    # Whether this tag node has a set of square brackets (e.g. `%tag[...]`)
    # following it that indicates its class and ID will be to the value of the
    # given object's {#to_key} or {#id} method (in that order).
    #
    # @return [true,false]
    def object_reference?
      @value[:object_ref] != 'nil'
    end

    # Source code for the contents of the node's object reference.
    #
    # @see http://haml.info/docs/yardoc/file.REFERENCE.html#object_reference_
    # @return [String,nil] string source of object reference or `nil` if it has
    #   not been defined
    def object_reference_source
      (@value[:object_ref] if object_reference?) || ''
    end

    # Whether this node had a `<` after it signifying that outer whitespace
    # should be removed.
    #
    # @return [true,false]
    def remove_inner_whitespace?
      @value[:nuke_inner_whitespace]
    end

    # Whether this node had a `>` after it signifying that outer whitespace
    # should be removed.
    #
    # @return [true,false]
    def remove_outer_whitespace?
      @value[:nuke_inner_whitespace]
    end

    # Returns the script source that will be evaluated to produce this tag's
    # inner content, if any.
    #
    # @return [String]
    def script
      (@value[:value] if @value[:parse]) || ''
    end

    # Returns the static inner content for this tag.
    #
    # If this tag contains dynamic content of any kind, this will still return
    # an empty string, and you'll have to use {#script} to obtain the source.
    #
    # @return [String]
    def text
      (@value[:value] if @value[:parse]) || ''
    end
  end
end
