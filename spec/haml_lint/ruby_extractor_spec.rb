require 'spec_helper'

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

      its(:source) { should == 'puts' }
      its(:source_map) { should == { 1 => 1 } }
    end

    context 'with multiple lines of plain text' do
      let(:haml) { <<-HAML }
        Hello world
        how are you?
      HAML

      its(:source) { should == "puts\nputs" }
      its(:source_map) { should == { 1 => 1, 2 => 2 } }
    end

    context 'with only tags with text content' do
      let(:haml) { <<-HAML }
        %h1 Hello World
        %p
          Lorem
          %b Ipsum
      HAML

      its(:source) { should == "puts # h1\nputs # p\nputs\nputs # b" }
      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 3, 4 => 4 } }
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

      its(:source) { should == "puts # tag\nscript" }
      its(:source_map) { should == { 1 => 1, 2 => 2 } }
    end

    context 'with a tag containing a script node' do
      let(:haml) { <<-HAML }
        %tag
          = script
      HAML

      its(:source) { should == "puts # tag\nscript" }
      its(:source_map) { should == { 1 => 1, 2 => 2 } }
    end

    context 'with a tag containing inline script' do
      let(:haml) { <<-HAML }
        %tag= script
      HAML

      its(:source) { should == "puts # tag\nscript" }
      its(:source_map) { should == { 1 => 1, 2 => 1 } }
    end

    context 'with a tag with hash attributes' do
      let(:haml) { <<-HAML }
        %tag{ one: 1, two: 2, 'three' => some_method }
      HAML

      its(:source) { should == "{}.merge(one: 1, two: 2, 'three' => some_method)\nputs # tag" }
      its(:source_map) { should == { 1 => 1, 2 => 1 } }
    end

    context 'with a tag with hash attributes with hashrockets and questionable spacing' do
      let(:haml) { <<-HAML }
        %tag.class_one.class_two#with_an_id{:type=>'checkbox', 'special' => :true }
      HAML

      its(:source) { should == "{:type=>'checkbox', 'special' => :true }\nputs # tag" }
      its(:source_map) { should == { 1 => 1, 2 => 1 } }
    end

    context 'with a tag with mixed-style hash attributes' do
      let(:haml) { <<-HAML }
        %tag.class_one.class_two#with_an_id{ :type=>'checkbox', special: 'true' }
      HAML

      its(:source) { should == "{}.merge(:type=>'checkbox', special: 'true')\nputs # tag" }
      its(:source_map) { should == { 1 => 1, 2 => 1 } }
    end

    context 'with a tag with hash attributes with a method call' do
      let(:haml) { <<-HAML }
        %tag{ tag_options_method }
      HAML

      its(:source) { should == "{}.merge(tag_options_method)\nputs # tag" }
      its(:source_map) { should == { 1 => 1, 2 => 1 } }
    end

    context 'with a tag with HTML-style attributes' do
      let(:haml) { <<-HAML }
        %tag(one=1 two=2 three=some_method)
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        {}.merge({\"one\" => 1,\"two\" => 2,\"three\" => some_method,})
        puts # tag
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1 } }
    end

    context 'with a tag with hash attributes and inline script' do
      let(:haml) { <<-HAML }
        %tag{ one: 1 }= script
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        {}.merge(one: 1)
        puts # tag
        script
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1 } }
    end

    context 'with a tag with hash attributes that span multiple lines' do
      let(:haml) { <<-HAML }
        %tag{ one: 1,
              two: 2,
              'three' => 3 }
      HAML

      its(:source) { should == "{}.merge(one: 1, two: 2, 'three' => 3)\nputs # tag" }
      its(:source_map) { should == { 1 => 1, 2 => 1 } }
    end

    context 'with a tag with 1.8-style hash attributes of string key/values' do
      let(:haml) { <<-HAML }
        %tag{ 'one' => '1', 'two' => '2' }
      HAML

      its(:source) { should == "{ 'one' => '1', 'two' => '2' }\nputs # tag" }
      its(:source_map) { should == { 1 => 1, 2 => 1 } }

      context 'that span multiple lines' do
        let(:haml) { <<-HAML }
          %div{ 'one' => '1',
                'two' => '2' }
        HAML

        its(:source) { should == "{ 'one' => '1', 'two' => '2' }\nputs # div" }
        its(:source_map) { should == { 1 => 1, 2 => 1 } }
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

    context 'with a filter with interpolated values' do
      let(:haml) { <<-HAML }
        :filter
          Some text \#{some_method} with interpolation.
          Some more text \#{some_other_method} with interpolation.
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        puts
        some_method
        some_other_method
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1 } }
    end

    context 'with a filter with interpolated values containing quotes' do
      let(:haml) { <<-HAML }
        :filter
          Some text \#{some_method("hello")}
          Some text \#{some_other_method('world')}
      HAML

      its(:source) { should == normalize_indent(<<-RUBY).rstrip }
        puts
        some_method("hello")
        some_other_method('world')
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1 } }
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
        puts
        some_method('hello',
                                 'world')
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 1, 3 => 1 } }
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
          puts
        else
          puts
        end
      RUBY

      its(:source_map) { should == { 1 => 1, 2 => 2, 3 => 4, 4 => 5, 5 => 1 } }
    end
  end
end
