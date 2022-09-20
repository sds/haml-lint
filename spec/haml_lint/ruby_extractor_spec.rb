# frozen_string_literal: true

describe HamlLint::RubyExtractor do
  let(:extractor) { described_class.new }

  describe '#extract' do
    let(:options) do
      {
        config: HamlLint::ConfigurationLoader.default_configuration,
      }
    end

    let(:tree) { HamlLint::Document.new(normalize_indent(haml), options) }
    subject { extractor.extract(tree) }

    context 'with an empty HAML document' do
      let(:haml) { '' }
      its(:source) { should == '' }
      its(:source_map) { should == {} }
    end

    context 'with plain text' do
      let(:haml) { <<-HAML }
        Hello world
      HAML

      its(:source) { should == '_haml_lint_puts_0' }
      its(:source_map) { should == { 1 => 1 } }
    end

    context 'with multiple lines of plain text' do
      let(:haml) { <<-HAML }
        Hello world
        how are you?
      HAML

      its(:source) { should == "_haml_lint_puts_0\n_haml_lint_puts_1" }
      its(:source_map) { should == { 1 => 1, 2 => 2 } }
    end

    context 'with only tags with text content' do
      let(:haml) { <<-HAML }
        %h1 Hello World
        %p
          Lorem
          %b Ipsum
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        _haml_lint_puts_0 # h1
        _haml_lint_puts_1 # h1/
        _haml_lint_puts_2 # p
        _haml_lint_puts_3
        _haml_lint_puts_4 # b
        _haml_lint_puts_5 # b/
        _haml_lint_puts_6 # p/
      RUBY
      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 2, 4 => 3, 5 => 4, 6 => 4, 7 => 2 } }
    end

    context 'with a silent script node' do
      let(:haml) { <<-HAML }
        - silent_script
      HAML

      its(:source) { should == 'silent_script' }
      its(:source_map) { should == { 1 => 1 } }
    end

    context 'with a script node' do
      let(:haml) { <<-HAML }
        = script
      HAML

      its(:source) { should == 'script' }
      its(:source_map) { should == { 1 => 1 } }
    end

    context 'with a script node that spans multiple lines' do
      let(:haml) { <<-HAML }
        = link_to 'Link',
                  path,
                  class: 'button'
      HAML

      its(:source) { should == "link_to 'Link', path, class: 'button'" }
      its(:source_map) { should == { 1 => 1 } }
    end

    context 'with a tag containing a silent script node' do
      let(:haml) { <<-HAML }
        %tag
          - script
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        _haml_lint_puts_0 # tag
        script
        _haml_lint_puts_1 # tag/
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 1 } }
    end

    context 'with a tag containing a script node' do
      let(:haml) { <<-HAML }
        %tag
          = script
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        _haml_lint_puts_0 # tag
        script
        _haml_lint_puts_1 # tag/
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 1 } }
    end

    context 'with a tag containing inline script' do
      let(:haml) { <<-HAML }
        %tag= script
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        _haml_lint_puts_0 # tag
        script
        _haml_lint_puts_1 # tag/
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1 } }
    end

    context 'with a tag with hash attributes' do
      let(:haml) { <<-HAML }
        %tag{ one: 1, two: 2, 'three' => some_method }
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        {}.merge(one: 1, two: 2, 'three' => some_method)
        _haml_lint_puts_0 # tag
        _haml_lint_puts_1 # tag/
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1 } }
    end

    context 'with a tag with hash attributes with hashrockets and questionable spacing' do
      let(:haml) { <<-HAML }
        %tag.class_one.class_two#with_an_id{:type=>'checkbox', 'special' => :true }
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        {:type=>'checkbox', 'special' => :true }
        _haml_lint_puts_0 # tag
        _haml_lint_puts_1 # tag/
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1 } }
    end

    context 'with a tag with mixed-style hash attributes' do
      let(:haml) { <<-HAML }
        %tag.class_one.class_two#with_an_id{ :type=>'checkbox', special: 'true' }
      HAML

      its(:source) { should == normalize_indent(<<-RUBY.rstrip) }
        {}.merge(:type=>'checkbox', special: 'true')
        _haml_lint_puts_0 # tag
        _haml_lint_puts_1 # tag/
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1 } }
    end

    context 'with a tag with hash attributes with a method call' do
      let(:haml) { <<-HAML }
        %tag{ tag_options_method }
      HAML

      its(:source) { should == normalize_indent(<<-RUBY.rstrip) }
        {}.merge(tag_options_method)
        _haml_lint_puts_0 # tag
        _haml_lint_puts_1 # tag/
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1 } }
    end

    context 'with a tag with HTML-style attributes' do
      let(:haml) { <<-HAML }
        %tag(one=1 two=2 three=some_method)
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        {}.merge({\"one\" => 1,\"two\" => 2,\"three\" => some_method,})
        _haml_lint_puts_0 # tag
        _haml_lint_puts_1 # tag/
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1 } }
    end

    context 'with a tag with hash attributes and inline script' do
      let(:haml) { <<-HAML }
        %tag{ one: 1 }= script
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        {}.merge(one: 1)
        _haml_lint_puts_0 # tag
        script
        _haml_lint_puts_1 # tag/
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1, 4 => 1 } }
    end

    context 'with a tag with hash attributes that span multiple lines' do
      let(:haml) { <<-HAML }
        %tag{ one: 1,
              two: 2,
              'three' => 3 }
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        {}.merge(one: 1,
        two: 2,
        'three' => 3)
        _haml_lint_puts_0 # tag
        _haml_lint_puts_1 # tag/
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 1 } }
    end

    # Multiline attributes were introduced in 5.2.1
    if Haml::VERSION >= '5.2.1'
      context 'with a tag with hash attributes containing a hash with newlines' do
        let(:haml) { <<-HAML }
          %tag{class: some_method({
            one: 1,
            two: 2
          })}
        HAML

        its(:source) { should == normalize_indent(<<-RUBY).rstrip }
          {}.merge(class: some_method({
          one: 1,
          two: 2
          }))
          _haml_lint_puts_0 # tag
          _haml_lint_puts_1 # tag/
        RUBY
      end

      context 'with a tag with hash attributes containing a method call with newlines' do
        let(:haml) { <<-HAML }
          %tag{class: some_method(
            1, 2, 3
          )}
        HAML

        its(:source) { should == normalize_indent(<<-RUBY).rstrip }
          {}.merge(class: some_method(
          1, 2, 3
          ))
          _haml_lint_puts_0 # tag
          _haml_lint_puts_1 # tag/
        RUBY
      end
    end

    context 'with a tag with 1.8-style hash attributes of string key/values' do
      let(:haml) { <<-HAML }
        %tag{ 'one' => '1', 'two' => '2' }
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        { 'one' => '1', 'two' => '2' }
        _haml_lint_puts_0 # tag
        _haml_lint_puts_1 # tag/
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1 } }

      context 'that span multiple lines' do
        let(:haml) { <<-HAML }
          %div{ 'one' => '1',
                'two' => '2' }
        HAML

        its(:source) { should == normalize_indent(<<-RUBY).rstrip }
          { 'one' => '1', 'two' => '2' }
          _haml_lint_puts_0 # div
          _haml_lint_puts_1 # div/
        RUBY

        its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1 } }
      end
    end

    context 'with a HAML comment' do
      let(:haml) { <<-HAML }
        -# rubocop:disable SomeCop
        = some_code
        -# rubocop:enable SomeCop
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        # rubocop:disable SomeCop
        some_code
        # rubocop:enable SomeCop
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 3 } }
    end

    context 'with a multiline HAML comment' do
      let(:haml) { <<-HAML }
        -# This is a HAML
           comment spanning
           multiple lines
        = some_code
        -# rubocop:enable SomeCop
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        # This is a HAML
        # comment spanning
        # multiple lines
        some_code
        # rubocop:enable SomeCop
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1, 4 => 4, 5 => 5 } }

      context 'with no leading spaces' do
        let(:haml) { <<-HAML }
          -#
            This is a HAML
            comment spanning
            multiple lines
        HAML

        its(:source) { should == normalize_indent(<<-RUBY).rstrip }
          #
          # This is a HAML
          # comment spanning
          # multiple lines
        RUBY

        its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1, 4 => 1 } }
      end

      context 'with nested' do
        let(:haml) { <<-HAML }
          =some_code do
            -#
              This is a HAML
              comment spanning
              multiple lines
        HAML

        its(:source) { should == normalize_indent(<<-RUBY).rstrip }
          some_code do
            #
            # This is a HAML
            # comment spanning
            # multiple lines
          end
        RUBY

        its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 2, 4 => 2, 5 => 2, 6 => 1 } }
      end
    end

    context 'with a block statement' do
      let(:haml) { <<-HAML }
        - if condition
          - script_one
        - elsif condition_two
          - script_two
        - else
          - script_three
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        if condition
          script_one
        elsif condition_two
          script_two
        else
          script_three
        end
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6, 7 => 1 } }
    end

    context 'with an anonymous block' do
      let(:haml) { <<-HAML }
        = link_to path do
          = script
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        link_to path do
          script
        end
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 1 } }
    end

    context 'with an anonymous block with a trailing comment' do
      let(:haml) { <<-HAML }
        - list.each do |var, var2| # Some comment
          = something
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        list.each do |var, var2| # Some comment
          something
        end
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 1 } }
    end

    context 'with a for loop' do
      let(:haml) { <<-HAML }
        - for value in list
          = value
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        for value in list
          value
        end
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 1 } }
    end

    context 'with a while loop' do
      let(:haml) { <<-HAML }
        - while value < 10
          = value
          - value += 1
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        while value < 10
          value
          value += 1
        end
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 3, 4 => 1 } }
    end

    context 'with a Ruby filter' do
      let(:haml) { <<-HAML }
        :ruby
          method_one
          if condition
            method_two
          end
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        method_one
        if condition
          method_two
        end
      RUBY

      its(:source_map) { should == { 1 => 2, 2 => 3, 3 => 4, 4 => 5 } }
    end

    context 'with a Ruby filter containing block keywords' do
      let(:haml) { <<-HAML }
        :ruby
          if condition
            do_something
          else
            do_something_else
          end
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        if condition
          do_something
        else
          do_something_else
        end
      RUBY

      its(:source_map) { should == { 1 => 2, 2 => 3, 3 => 4, 4 => 5, 5 => 6 } }

      context 'and the filter is nested' do
        let(:haml) { <<-HAML }
          - something do
            :ruby
              if condition
                do_something
              else
                do_something_else
              end
        HAML

        its(:source) { should == normalize_indent(<<-RUBY).rstrip }
          something do
            if condition
              do_something
            else
              do_something_else
            end
          end
        RUBY

        its(:source_map) { should == { 1 => 1, 2 => 3, 3 => 4, 4 => 5, 5 => 6, 6 => 7, 7 => 1 } }
      end
    end

    context 'with a Ruby filter containing block keywords' do
      let(:haml) { <<-HAML }
        :ruby
          def foo
            42
          end

          def bar
            23
          end
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        def foo
          42
        end

        def bar
          23
        end
      RUBY
    end

    context 'with a filter with interpolated values' do
      let(:haml) { <<-HAML }
        :filter
          Some text \#{some_method} with interpolation.
          Some more text \#{some_other_method} with interpolation.
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        _haml_lint_puts_0 # :filter
        some_method
        some_other_method
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 3 } }
    end

    context 'with a filter with interpolated values containing quotes' do
      let(:haml) { <<-HAML }
        :filter
          Some text \#{some_method("hello")}
          Some text \#{some_other_method('world')}
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        _haml_lint_puts_0 # :filter
        some_method("hello")
        some_other_method('world')
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 3 } }
    end

    context 'with a filter with interpolated values spanning multiple lines' do
      let(:haml) { <<-HAML }
        :filter
          Some text \#{some_method('hello',
                                   'world')}
      HAML

      # TODO: Figure out if it's worth normalizing indentation for the generated
      # code in this interpolated context
      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        _haml_lint_puts_0 # :filter
        some_method('hello',
                                 'world')
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 2 } }
    end

    context 'with an if/else block containing only filters' do
      let(:haml) { <<-HAML }
        - if condition
          :filter
            Some text
        - else
          :filter
            Some other text
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        if condition
          _haml_lint_puts_0 # :filter
        else
          _haml_lint_puts_1 # :filter
        end
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 4, 4 => 5, 5 => 1 } }
    end
  end
end
