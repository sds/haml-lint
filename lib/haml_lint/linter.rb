# frozen_string_literal: true

module HamlLint
  # Base implementation for all lint checks.
  #
  # @abstract
  class Linter
    include HamlVisitor

    # List of lints reported by this linter.
    #
    # @todo Remove once spec/support/shared_linter_context returns an array of
    #   lints for the subject instead of the linter itself.
    attr_reader :lints

    # Initializes a linter with the specified configuration.
    #
    # @param config [Hash] configuration for this linter
    def initialize(config)
      @config = config
      @lints = []
    end

    # Runs the linter against the given Haml document.
    #
    # @param document [HamlLint::Document]
    def run(document, autocorrect: nil) # rubocop:disable Metrics
      run_or_raise(document, autocorrect: autocorrect)
    rescue Parser::SyntaxError => e
      location = e.diagnostic.location
      @lints <<
        HamlLint::Lint.new(
          HamlLint::Linter::Syntax.new(config),
          document.file,
          location.line,
          e.to_s,
          :error
        )
    rescue StandardError => e
      msg = +"Couldn't process the file"
      if @autocorrect
        # Those lints related to auto-correction were not saved, so don't display them
        @lints = []
        msg << " for autocorrect '#{@autocorrect}'. "
      else
        msg << ' for linting. '
      end

      msg << "#{e.class.name}: #{e.message}"
      if ENV['HAML_LINT_DEBUG'] == 'true'
        msg << "(DEBUG: Backtrace follows)\n#{e.backtrace.join("\n")}\n------"
      end

      @lints << HamlLint::Lint.new(self, document.file, nil, msg, :error)
      @lints
    end

    # Runs the linter against the given Haml document, raises if the file cannot be processed due to
    # Syntax or Haml-Lint internal errors. (For testing purposes)
    #
    # @param document [HamlLint::Document]
    def run_or_raise(document, autocorrect: nil)
      @document = document
      @lints = []
      @autocorrect = autocorrect
      reset_autocorrect_state
      visit(document.tree)
      @lints
    end

    # Returns the simple name for this linter.
    #
    # @return [String]
    def name
      self.class.name.to_s.split('::').last
    end

    # Returns true if this linter supports autocorrect, false otherwise
    #
    # @return [Boolean]
    def self.supports_autocorrect?
      @supports_autocorrect || false
    end

    def supports_autocorrect?
      self.class.supports_autocorrect?
    end

    # Returns whether this linter's autocorrect is safe. Defaults to true (safe)
    # unless the linter declares otherwise via `autocorrect_safe(false)`.
    #
    # @return [Boolean]
    def self.autocorrect_safe?
      @autocorrect_safe != false
    end

    # The autocorrect ordering priority for this linter. During autocorrect,
    # linters with a lower priority run first and higher priority run later,
    # against the same (already mutated) document. Linters with the same priority
    # keep their default (alphabetical) order.
    #
    # Called with an argument (e.g. `autocorrect_priority(1)`) in a linter's
    # top-level scope, it sets the priority; called with no argument it reads it.
    # The default, when never set, is 0.
    #
    # @param value [Integer, nil] the new priority, or nil to read the current one
    # @return [Integer]
    def self.autocorrect_priority(value = nil)
      @autocorrect_priority = value unless value.nil?
      @autocorrect_priority || 0
    end

    private

    attr_reader :config, :document

    # Linters can call supports_autocorrect(true) in their top-level scope to indicate that
    # they supports autocorrect.
    #
    # @params value [Boolean] The new value for supports_autocorrect
    private_class_method def self.supports_autocorrect(value)
      @supports_autocorrect = value
    end

    # Linters can call autocorrect_safe(false) in their top-level scope to declare that their
    # autocorrect is unsafe, meaning it only runs under `--auto-correct-all` (`:all`).
    # The default, when not called, is safe.
    #
    # @params value [Boolean] The new value for autocorrect_safe
    private_class_method def self.autocorrect_safe(value)
      @autocorrect_safe = value
    end

    # Resets the per-run autocorrect bookkeeping. Linter instances are reused
    # across files, so subclasses that accumulate extra autocorrect state during
    # a traversal (e.g. a list of lines to merge or delete) must override this,
    # calling `super`, to clear that state between files. Otherwise corrections
    # from one file leak into the next.
    def reset_autocorrect_state
      @autocorrected_lines = nil
      @autocorrect_changed = false
    end

    # Whether the linter is currently allowed to apply autocorrections, given the active
    # autocorrect mode and this linter's declared safety:
    #
    #   * safe linters correct under both `:safe` and `:all`;
    #   * unsafe linters correct only under `:all`;
    #   * with no mode (`nil`) nothing is corrected (detection only).
    #
    # @return [Boolean]
    def autocorrect?
      case @autocorrect
      when :all
        true
      when :safe
        self.class.autocorrect_safe?
      else
        false
      end
    end

    # Applies a corrected, full-document source to the document through the single
    # mutation path (`Document#change_source`), but only when the safety gate permits.
    # No-ops otherwise; `change_source` itself also no-ops when the source is unchanged.
    #
    # @param new_source [String] the corrected Haml source
    def apply_autocorrect(new_source)
      return unless autocorrect?
      document.change_source(new_source)
    end

    # Lazily-initialized working copy of the document's source lines, used to
    # accumulate line-level corrections during a single tree traversal. Editing
    # this copy (rather than calling `apply_autocorrect` per node) avoids
    # reparsing the document mid-walk, which would invalidate the tree being
    # visited.
    #
    # @return [Array<String>]
    def autocorrected_lines
      @autocorrected_lines ||= document.source_lines.dup
    end

    # Replaces a single source line (0-indexed) in the working copy, but only
    # when autocorrect is permitted and the new text actually differs.
    #
    # @param index [Integer] the 0-indexed line to replace
    # @param new_text [String] the corrected line
    # @return [Boolean] true if a change was recorded, false otherwise
    def correct_line(index, new_text)
      return false unless autocorrect?
      return false if autocorrected_lines[index] == new_text

      autocorrected_lines[index] = new_text
      @autocorrect_changed = true
    end

    # Flushes any corrections accumulated via `correct_line` through the single
    # mutation path, once, after the whole tree has been visited. Defined on the
    # base so per-node linters need no boilerplate; no-ops for linters that never
    # accumulated a change (including those that apply within `visit_root`).
    #
    # NOTE: a linter that overrides `after_visit_root` must call `super`, or
    # accumulated corrections will not be applied.
    def after_visit_root(_node)
      return unless @autocorrect_changed

      apply_autocorrect(autocorrected_lines.join("\n"))
    end

    # Record a lint for reporting back to the user.
    #
    # @param node_or_line [#line] line number or node to extract the line number from
    # @param message [String] error/warning to display to the user
    def record_lint(node_or_line, message, corrected: false)
      line = node_or_line.is_a?(Integer) ? node_or_line : node_or_line.line
      @lints << HamlLint::Lint.new(self, @document.file, line, message,
                                   config.fetch('severity', :warning).to_sym,
                                   corrected: corrected)
    end

    # Parse Ruby code into an abstract syntax tree.
    #
    # @return [AST::Node]
    def parse_ruby(source)
      self.class.ruby_parser.parse(source)
    end

    def self.ruby_parser # rubocop:disable Lint/IneffectiveAccessModifier
      @ruby_parser ||= HamlLint::RubyParser.new
    end

    # Remove the surrounding double quotes from a string, ignoring any
    # leading/trailing whitespace.
    #
    # @param string [String]
    # @return [String] stripped with leading/trailing double quotes removed.
    def strip_surrounding_quotes(string)
      string[/\A\s*"(.*)"\s*\z/, 1]
    end

    # Returns whether a string contains any interpolation.
    #
    # @param string [String]
    # @return [true,false]
    def contains_interpolation?(string)
      return false unless string
      Haml::Util.contains_interpolation?(string)
    end

    # Returns whether this tag node has inline script, e.g. is of the form
    # %tag= ...
    #
    # @param tag_node [HamlLint::Tree::TagNode]
    # @return [true,false]
    def tag_has_inline_script?(tag_node)
      tag_with_inline_content = tag_with_inline_text(tag_node)
      return false unless inline_content = inline_node_content(tag_node)
      return false unless index = tag_with_inline_content.rindex(inline_content)

      index -= 1
      index -= 1 while [' ', '"', "'"].include?(tag_with_inline_content[index])

      tag_with_inline_content[index] == '='
    end

    # Returns whether the inline content for a node is a string.
    #
    # For example, the following node has a literal string:
    #
    #   %tag= "A literal #{string}"
    #
    # whereas this one does not:
    #
    #   %tag A literal #{string}
    #
    # @param node [HamlLint::Tree::Node]
    # @return [true,false]
    def inline_content_is_string?(node)
      tag_with_inline_content = tag_with_inline_text(node)
      inline_content = inline_node_content(node)

      index = tag_with_inline_content.rindex(inline_content) - 1

      %w[' "].include?(tag_with_inline_content[index])
    end

    # Get the inline content for this node.
    #
    # Inline content is the content that appears inline right after the
    # tag/script. For example, in the code below...
    #
    #   %tag Some inline content
    #
    # ..."Some inline content" would be the inline content.
    #
    # @param node [HamlLint::Tree::Node]
    # @return [String]
    def inline_node_content(node)
      inline_content = node.script

      if contains_interpolation?(inline_content)
        strip_surrounding_quotes(inline_content)
      else
        inline_content
      end
    end

    # Gets the next node following this node, ascending up the ancestor chain
    # recursively if this node has no siblings.
    #
    # @param node [HamlLint::Tree::Node]
    # @return [HamlLint::Tree::Node,nil]
    def next_node(node)
      return unless node
      siblings = node.parent ? node.parent.children : [node]

      next_sibling = siblings[siblings.index(node) + 1] if siblings.count > 1
      return next_sibling if next_sibling

      next_node(node.parent)
    end

    # Returns the line of the "following node" (child of this node or sibling or
    # the last line in the file).
    #
    # @param node [HamlLint::Tree::Node]
    def following_node_line(node)
      [
        [node.children.first, next_node(node)].compact.map(&:line),
        @document.source_lines.count + 1,
      ].flatten.min
    end

    # Extracts all text for a tag node and normalizes it, including additional
    # lines following commas or multiline bar indicators ('|')
    #
    # @param tag_node [HamlLine::Tree::TagNode]
    # @return [String] source code of original parse node
    def tag_with_inline_text(tag_node)
      # Normalize each of the lines to ignore the multiline bar (|) and
      # excess whitespace
      @document.source_lines[(tag_node.line - 1)...(following_node_line(tag_node) - 1)]
               .map do |line|
        line.strip.delete_suffix('|').rstrip
      end.join(' ')
    end
  end
end
