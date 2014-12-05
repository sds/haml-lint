require 'spec_helper'

describe HamlLint::ScriptExtractor do
  let(:parser) { HamlLint::Parser.new(normalize_indent(haml)) }
  let(:extractor) { described_class.new(parser) }

  describe '#extract' do
    subject { extractor.extract }

    context 'with an empty HAML document' do
      let(:haml) { '' }
      it { should == '' }
    end

    context 'with plain text' do
      let(:haml) { <<-HAML }
        Hello world
      HAML

      it { should == 'puts # Hello world' }
    end

    context 'with only tags with text content' do
      let(:haml) { <<-HAML }
        %h1 Hello World
        %p
          Lorem
          %b Ipsum
      HAML

      it { should == "puts # h1\nputs # p\nputs # Lorem\nputs # b" }
    end

    context 'with a silent script node' do
      let(:haml) { <<-HAML }
        - silent_script
      HAML

      it { should == 'silent_script' }
    end

    context 'with a script node' do
      let(:haml) { <<-HAML }
        = script
      HAML

      it { should == 'script' }
    end

    context 'with a script node that spans multiple lines' do
      let(:haml) { <<-HAML }
        = link_to 'Link',
                  path,
                  class: 'button'
      HAML

      it { should == "link_to 'Link', path, class: 'button'" }
    end

    context 'with a tag containing a silent script node' do
      let(:haml) { <<-HAML }
        %tag
          - script
      HAML

      it { should == "puts # tag\nscript" }
    end

    context 'with a tag containing a script node' do
      let(:haml) { <<-HAML }
        %tag
          = script
      HAML

      it { should == "puts # tag\nscript" }
    end

    context 'with a tag containing inline script' do
      let(:haml) { <<-HAML }
        %tag= script
      HAML

      it { should == "puts # tag\nscript" }
    end

    context 'with a tag with hash attributes' do
      let(:haml) { <<-HAML }
        %tag{ one: 1, two: 2, 'three' => some_method }
      HAML

      it { should == "{}.merge(one: 1, two: 2, 'three' => some_method)\nputs # tag" }
    end

    context 'with a tag with HTML-style attributes' do
      let(:haml) { <<-HAML }
        %tag(one=1 two=2 three=some_method)
      HAML

      it { should == "{}.merge({\"one\" => 1,\"two\" => 2,\"three\" => some_method,})\nputs # tag" }
    end

    context 'with a tag with hash attributes and inline script' do
      let(:haml) { <<-HAML }
        %tag{ one: 1 }= script
      HAML

      it { should == normalize_indent(<<-RUBY).rstrip }
        {}.merge(one: 1)
        puts # tag
        script
      RUBY
    end

    context 'with a tag with hash attributes that span multiple lines' do
      let(:haml) { <<-HAML }
        %tag{ one: 1,
              two: 2,
              'three' => 3 }
      HAML

      it { should == "{}.merge(one: 1, two: 2, 'three' => 3)\nputs # tag" }
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

      it { should == normalize_indent(<<-RUBY).rstrip }
        if condition
          script_one
        elsif condition_two
          script_two
        else
          script_three
        end
      RUBY
    end

    context 'with an anonymous block' do
      let(:haml) { <<-HAML }
        = link_to path do
          = script
      HAML

      it { should == normalize_indent(<<-RUBY).rstrip }
        link_to path do
          script
        end
      RUBY
    end

    context 'with a for loop' do
      let(:haml) { <<-HAML }
        - for value in list
          = value
      HAML

      it { should == normalize_indent(<<-RUBY).rstrip }
        for value in list
          value
        end
      RUBY
    end

    context 'with a while loop' do
      let(:haml) { <<-HAML }
        - while value < 10
          = value
          - value += 1
      HAML

      it { should == normalize_indent(<<-RUBY).rstrip }
        while value < 10
          value
          value += 1
        end
      RUBY
    end

    context 'with a Ruby filter' do
      let(:haml) { <<-HAML }
        :ruby
          method_one
          if condition
            method_two
          end
      HAML

      it { should == normalize_indent(<<-RUBY).rstrip }
        method_one
        if condition
          method_two
        end
      RUBY
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

      it { should == normalize_indent(<<-RUBY).rstrip }
        if condition
          do_something
        else
          do_something_else
        end
      RUBY

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

        it { should == normalize_indent(<<-RUBY).rstrip }
          something do
            if condition
              do_something
            else
              do_something_else
            end
          end
        RUBY
      end
    end

    context 'with a filter with interpolated values' do
      let(:haml) { <<-HAML }
        :filter
          Some text \#{some_method} with interpolation.
          Some more text \#{some_other_method} with interpolation.
      HAML

      it { should == normalize_indent(<<-RUBY).rstrip }
        some_method
        some_other_method
      RUBY
    end

    context 'with a filter with interpolated values containing quotes' do
      let(:haml) { <<-HAML }
        :filter
          Some text \#{some_method("hello")}
          Some text \#{some_other_method('world')}
      HAML

      it { should == normalize_indent(<<-RUBY).rstrip }
        some_method("hello")
        some_other_method('world')
      RUBY
    end

    context 'with a filter with interpolated values spanning multiple lines' do
      let(:haml) { <<-HAML }
        :filter
          Some text \#{some_method('hello',
                                   'world')}
      HAML

      # TODO: Figure out if it's worth normalizing indentation for the generated
      # code in this interpolated context
      it { should == normalize_indent(<<-RUBY).rstrip }
        some_method('hello',
                                 'world')
      RUBY
    end
  end
end
