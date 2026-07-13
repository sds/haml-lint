# frozen_string_literal: true

describe HamlLint::Linter::UnnecessaryStringOutput do
  include_context 'linter'

  context 'when tag is empty' do
    let(:haml) { <<-HAML }
      %tag
    HAML
    it { should_not report_lint }
  end

  context 'when tag contains inline text without interpolation' do
    let(:haml) { '%tag Some inline text' }
    it { should_not report_lint }
  end

  context 'when tag outputs string with interpolation' do
    let(:haml) { '%tag= "Some #{interpolation} text"' }
    it { should report_lint }
  end

  context 'when tag contains inline text with interpolation' do
    let(:haml) { '%tag Some #{interpolation} text' }
    it { should_not report_lint }
  end

  context 'when tag contains inline text with double quotes' do
    let(:haml) { '%tag "Some #{interpolation} text"' }
    it { should_not report_lint }
  end

  context 'when tag contains inline text with single quotes' do
    let(:haml) { "%tag 'Some text'" }
    it { should_not report_lint }
  end

  context 'when script outputs literal string in double quotes' do
    let(:haml) { '= "hello #{world}"' }
    it { should report_lint }
  end

  context 'when script outputs literal string in single quotes' do
    let(:haml) { "= 'hello world'" }
    it { should report_lint }
  end

  context 'when tag contains nested text with interpolation' do
    let(:haml) { <<-'HAML' }
      %tag
        Some #{interpolated} text
    HAML

    it { should_not report_lint }
  end

  context 'when script outputs literal string with method called on it' do
    let(:haml) { "= 'user'.pluralize(@users.count)" }

    it { should_not report_lint }
  end

  context 'when script outputs literal string starting with an HTML comment character' do
    let(:haml) { '= "/ Something"' }

    it { should_not report_lint }
  end

  context 'when script outputs literal string starting with a hash sign' do
    let(:haml) { '= "# Something"' }

    it { should_not report_lint }
  end

  context 'when script outputs literal string starting with a dash' do
    let(:haml) { '= "- Something"' }

    it { should_not report_lint }
  end

  context 'when script outputs literal string starting with a equals sign' do
    let(:haml) { '= "= Something"' }

    it { should_not report_lint }
  end

  context 'when script outputs literal string starting with a percent sign' do
    let(:haml) { '= "% Something"' }

    it { should_not report_lint }
  end

  context 'when script outputs literal string starting with a tilde' do
    let(:haml) { '= "~ Something"' }

    it { should_not report_lint }
  end

  context 'when script outputs string starting with a special character then interpolation' do
    let(:haml) { '= "/ #{interpolation}"' }

    it { should_not report_lint }
  end

  context 'when script outputs literal string starting with interpolation' do
    let(:haml) { '= "#{variable}"' }

    it { should report_lint }
  end

  context 'when script outputs a string containing a unicode escape sequence' do
    let(:haml) { '= "#{price}\u202F\u0243"' }

    it { should_not report_lint }
  end

  context 'when script outputs a string containing a tab escape sequence' do
    let(:haml) { '= "first\tsecond"' }

    it { should_not report_lint }
  end

  context 'when script outputs a string with a trailing space' do
    let(:haml) { '= "#{label}: "' }

    it { should_not report_lint }
  end

  context 'when script outputs a string with a leading space' do
    let(:haml) { '= " #{value}"' }

    it { should_not report_lint }
  end

  context 'when script outputs a string whose interior contains whitespace' do
    let(:haml) { '= "#{first} and #{second}"' }

    it { should report_lint }
  end

  context 'when script is a comment' do
    let(:haml) { '=# comment' }

    it { should_not report_lint }
  end

  context 'when equals sign appears in the middle of the line' do
    let(:haml) { '#{quantity} x #{amount} = #{price}' }

    it { should_not report_lint }
  end

  context 'with autocorrect' do
    let(:autocorrect) { :all }

    context 'when a tag outputs a string with interpolation' do
      let(:haml) { '%tag= "Some #{interpolation} text"' }

      it 'rewrites it as inline plain text' do
        subject
        document.source.should == '%tag Some #{interpolation} text'
      end

      it 'records the lint as corrected' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == true
      end
    end

    context 'when the tag has attributes' do
      let(:haml) { '%p.foo{ id: "x" }= "bar #{value}"' }

      it 'preserves the tag, classes and attributes' do
        subject
        document.source.should == '%p.foo{ id: "x" } bar #{value}'
      end
    end

    context 'when a script outputs a double-quoted string with interpolation' do
      let(:haml) { '= "hello #{world}"' }

      it 'rewrites it as plain text' do
        subject
        document.source.should == 'hello #{world}'
      end
    end

    context 'when a script outputs a single-quoted literal string' do
      let(:haml) { "= 'hello world'" }

      it 'rewrites it as plain text' do
        subject
        document.source.should == 'hello world'
      end
    end

    context 'when a script outputs a string starting with interpolation' do
      let(:haml) { '= "#{variable}"' }

      it 'rewrites it as plain text, keeping the interpolation' do
        subject
        document.source.should == '#{variable}'
      end
    end

    context 'when a single-quoted literal contains interpolation syntax' do
      let(:haml) { %q(= 'a #{foo} b') }

      it 'escapes the interpolation so it stays literal' do
        subject
        document.source.should == 'a \#{foo} b'
      end
    end

    context 'when the script is nested under a tag' do
      let(:haml) { <<-'HAML' }
        %div
          = "hello #{world}"
      HAML

      it 'rewrites it as plain text while preserving indentation' do
        subject
        document.source.should == "%div\n  hello \#{world}\n"
      end
    end

    context 'when the tag outputs unescaped HTML' do
      let(:haml) { '%tag!= "un #{safe}"' }

      it 'reports the lint but does not change the unescaped output' do
        subject
        subject.lints.size.should == 1
        subject.lints.first.corrected.should == false
        document.source_was_changed.should == false
      end
    end

    context 'under :safe mode' do
      let(:autocorrect) { :safe }
      let(:haml) { '= "hello #{world}"' }

      it 'reports the lint but does not correct it' do
        subject
        subject.lints.first.corrected.should == false
        document.source_was_changed.should == false
      end
    end

    context 'when there is nothing to correct' do
      let(:haml) { '%tag Some inline text' }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end

    context 'when the linter is disabled inline' do
      let(:haml) { "-# haml-lint:disable UnnecessaryStringOutput\n= \"hello\"" }

      it 'does not change the source' do
        subject
        document.source_was_changed.should == false
      end
    end
  end
end
