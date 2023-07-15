# Linters

Below is a list of linters supported by `haml-lint`, ordered alphabetically.

* [AlignmentTabs](#alignmenttabs)
* [AltText](#alttext)
* [ClassAttributeWithStaticValue](#classattributewithstaticvalue)
* [ClassesBeforeIds](#classesbeforeids)
* [ConsecutiveComments](#consecutivecomments)
* [ConsecutiveSilentScripts](#consecutivesilentscripts)
* [EmptyObjectReference](#emptyobjectreference)
* [EmptyScript](#emptyscript)
* [FinalNewline](#finalnewline)
* [HtmlAttributes](#htmlattributes)
* [IdNames](#idnames)
* [ImplicitDiv](#implicitdiv)
* [Indentation](#indentation)
* [InlineStyles](#inlinestyles)
* [InstanceVariables](#instancevariables)
* [LeadingCommentSpace](#leadingcommentspace)
* [LineLength](#linelength)
* [MultilinePipe](#multilinepipe)
* [MultilineScript](#multilinescript)
* [NoPlaceholders](#noplaceholders)
* [ObjectReferenceAttributes](#objectreferenceattributes)
* [RepeatedId](#repeatedid)
* [RuboCop](#rubocop)
* [RubyComments](#rubycomments)
* [SpaceBeforeScript](#spacebeforescript)
* [SpaceInsideHashAttributes](#spaceinsidehashattributes)
* [TagName](#tagname)
* [TrailingEmptyLines](#trailingemptylines)
* [TrailingWhitespace](#trailingwhitespace)
* [UnnecessaryInterpolation](#unnecessaryinterpolation)
* [UnnecessaryStringOutput](#unnecessarystringoutput)
* [ViewLength](#viewlength)

## AlignmentTabs

Don't use tabs for alignment within a tag.

**Bad**
```haml
%div
  %p		Hello, world
  %span	This is visually aligned with its sibling's content using tabs
```

**Acceptable, though not recommended**
```haml
%div
  %p    Hello, world
  %span This is visually aligned with its sibling's content using spaces
```

**Good**
```haml
%div
  %p Hello, world
  %span This does not worry about alignment of tag text
```

## AltText

`img` tags should have an accompanying `alt` attribute containing alternate
text.

**Bad**
```haml
%img{ src: 'my-photo.jpg' }
```

**Good**
```haml
%img{ alt: 'Photo of me', src: 'my-photo.jpg' }
```

Include `alt` attributes is important for making your site more accessible.
See the
[W3C guidelines](http://www.w3.org/TR/2008/REC-WCAG20-20081211/#text-equiv-all)
for details.

## ClassAttributeWithStaticValue

Prefer static class attributes over hash attributes with static values.

**Bad**
```haml
%tag{ class: 'my-class' }
```

**Good**
```haml
%tag.my-class
```

Unless you are assigning a dynamic value to the class attribute, it is terser
to use the inline tag syntax to specify the class(es) an element should be
assigned.

## ClassesBeforeIds

Whether classes or ID attributes should be listed first in tags.

### EnforcedStyle: 'class' (default)

**Bad: ID before class**
```haml
%tag#id.class
```

**Good**
```haml
%tag.class#id
```

These attributes should be listed in order of their specificity. Since the tag
name (if specified) always comes first and has the lowest specificity, classes
and then IDs should follow.

### EnforcedStyle: 'id'

**Bad: Class before ID**
```haml
%tag.class#id
```

**Good**
```haml
%tag#id.class
```

As IDs are more significant than classes to the element they represent, IDs
should be listed first and then classes should follow. This gives a more
consistent vertical alignment of IDs.

## ConsecutiveComments

Option            | Description
------------------|-------------------------------------------------------------
`max_consecutive` | Maximum number of consecutive comments allowed before warning (default `1`)

Consecutive comments should be condensed into a single multiline comment.

**Bad**
```haml
-# A collection
-# of many
-# consecutive comments
```

**Good**
```haml
-#
  A multiline comment
  is much more clean
  and concise
```

## ConsecutiveSilentScripts

Option            | Description
------------------|-------------------------------------------------------------
`max_consecutive` | Maximum number of consecutive scripts allowed before warning (default `2`)

Avoid writing multiple lines of Ruby using silent script markers (`-`).

**Bad**
```haml
- expression_one
- expression_two
- expression_three
```

**Better**
```haml
:ruby
  expression_one
  expression_two
  expression_three
```

In general, large blocks of Ruby code in HAML templates are a smell, and this
check serves to warn you of that. However, for the cases where having the code
inline can improve readability, you can signal your intention by using a
`:ruby` filter block instead.

## EmptyObjectReference

Empty object references are no-ops and can safely be removed.

**Bad**
```haml
%tag[]
```

**Good**
```haml
%tag
```

These serve no purpose and are usually left behind by mistake.

## EmptyScript

Don't write empty scripts.

**Bad: script marker with no code**
```haml
-
```

**Good**
```haml
- some_expression
```

These serve no purpose and are usually left behind by mistake.

## FinalNewline

Files should always have a final newline. This results in better diffs when
adding lines to the file, since SCM systems such as `git` won't think that you
touched the last line if you append to the end of a file.

You can customize whether or not a final newline exists with the `present`
option.

Configuration Option | Description
---------------------|---------------------------------------------------------
`present`            | Whether a final newline should be present (default `true`)

## HtmlAttributes

Don't use the
[HTML-style attributes](http://haml.info/docs/yardoc/file.REFERENCE.html#htmlstyle_attributes_)
syntax to define attributes for an element.

**Bad**
```haml
%tag(lang=en)
```

**Good**
```haml
%tag{ lang: 'en' }
```

While the HTML-style attributes syntax can be terser, it introduces additional
complexity to your templates as there are now two different ways to define
attributes. Standardizing on when to use HTML-style versus hash-style adds
greater cognitive load when writing templates. Using one style makes this
easier.

## IdNames

Check the naming conventions of id attributes against one of two possible
preferred styles, `lisp_case` (default), `camel_case`, `pascal_case`, or
`snake_case`:

**Bad: inconsistent id names**
```haml
#lisp-case
#camelCase
#PascalCase
#snake_case
```

**With default `lisp_case` style option: require ids in lisp-case-format**
```haml
#lisp-case
```

**With `camel_case` style option: require ids in camelCaseFormat**
```haml
#camelCase
```

**With `pascal_case` style option: require ids in PascalCaseFormat**
```haml
#PascalCase
```

**With `snake_case` style option: require ids in snake_case_format*
```haml
#snake_case
%div{ id: 'snake_case' }
```

## ImplicitDiv

Avoid writing `%div` when it would otherwise be implicit.

**Bad: `div` is unnecessary when class/ID is specified**
```haml
%div.button
```

**Good: `div` is required when no class/ID is specified**
```haml
%div
```

**Good**
```haml
.button
```

HAML was designed to be concise, and not embracing this philosophy makes the
tool less useful.

## Indentation

Check that spaces are used for indentation instead of hard tabs.

Option          | Description
----------------|-------------------------------------------------------------
`character`     | Character to use for indentation. `space` or `tab` (default `space`)
`width`         | Number of spaces to use for `space` indentation. (default 2)

**Bad: indentation is 1 space**
```haml
%button
 Hit me
```

**Bad: indentation is 4 spaces**
```haml
%button
    Hit me
```

**Good: indentation is 2 spaces**
```haml
%button
  Hit me
```

**Note:** `width` is ignored when `character` is set to `tab`.

## InlineStyles

Tags should not contain inline style attributes.

**Bad**
```haml
%p{ style: 'color: red;' }
```

**Good**
```haml
%p.warning
```

Exceptions may need to be made for dynamic content and email templates.

See [CodeAcademy](https://www.codecademy.com/articles/html-inline-styles) to
learn more.

## InstanceVariables

Checks that instance variables are not used in the specified type of files.

Option          | Description
----------------|-------------------------------------------------------------
`file_types`    | The class of files to lint (default `partial`)
`matchers`      | The regular expressions to check file names against.

By default, this linter only runs on Rails-style partial views, e.g. files that
have a base name starting with a leading underscore `_`. If you want to ensure
that you don't use any instance variables at all, you can set `file_types` to
`all`.

You can also define your own matchers if you want to enable this linter on
a different subset of your views. For instance, if you want to lint only files
starting with `special_`, you can define the configuration as follows:

```yaml
InstanceVariables:
  enabled: true
  file_types: special
  matchers:
    special: ^special_.*\.haml$
```

To avoid using instance variables in partials, ensure you are passing any needed
variables as local variables. Alternatively, you can use only helper methods to
place data in your views.

## LeadingCommentSpace

Separate comments from the leading `#` by a space.

**Bad**
```haml
-#Comment with no space
```

**Good**
```haml
-# Comment with space
```

The latter is more readable.

## LineLength

Option | Description
-------|-----------------------------------------------------------------
`max`  | Maximum number of columns a single line can have. (default `80`)

Wrap lines at 80 characters. You can configure this amount via the `max`
option on the linter, e.g. by adding the following to your `.haml-lint.yml`:

```yaml
linters:
  LineLength:
    max: 100
```

Long lines are harder to read and usually indicative of complexity. You can
avoid them by splitting long attribute hashes on a comma, for example:

```haml
%tag{ attr1: 1,
      attr2: 2,
      attr3: 3 }
```

This significantly improves readability.

## MultilinePipe

Don't span multiple lines using the multiline pipe (`|`) syntax.

**Bad**
```haml
%p= 'Some' + |
    'long' + |
    'string' |
```

**Good: use helpers to generate long dynamic strings**
```haml
%p= generate_long_string
```

**Good: split long method calls on commas**
```haml
%p= some_helper_method(some_value,
                       another_value,
                       yet_another_value)
```

**Good: split attribute definitions/hashes on commas**
```haml
%p{ data: { value: value,
            name: name } }
```

The multiline bar was
[made awkward intentionally](http://haml.info/docs/yardoc/file.REFERENCE.html#multiline).
`haml-lint` takes this a step further by discouraging its use entirely, as it
almost always suggests an unnecessarily complicated template that should have
its logic extracted into a helper.

## MultilineScript

Don't span Ruby script over multiple lines using operators.

**Bad**
```haml
- if condition ||
-    other_condition
  Display something!
```

**Good**
```haml
- if condition || other_condition
  Display something!
```

While writing code this way may sometimes work, it is actually a result of a
quirk in how HAML generates code from a template. While the following code
will compile and run:

```haml
- if condition ||
-    other_condition
  Display something!
```

...this code will fail with a parse error:

```haml
- if condition ||
-    other_condition
  Display something!
- else
  Otherwise display this!
```

Thus it's best to stay away from writing code this way.

## NoPlaceholders

Don't use HTML placeholder attributes.

**Bad**
```haml
%input{ placeholder: 'Placeholders arent very accessible' }
```

**Good**
```haml
#my-details Placeholders arent very accessible
%input{ 'aria-describedby': 'my-details' }
```

Placeholder attributes are considered an
[anti-pattern](https://www.smashingmagazine.com/2018/06/placeholder-attribute/).

## ObjectReferenceAttributes

Don't use the
[object reference syntax](http://haml.info/docs/yardoc/file.REFERENCE.html#object_reference_)
to set the class/id of an element.

**Bad**
```haml
%li[@user]
  = @user.name
```

**Good**
```haml
%li.user{ id: "user_#{@user.id}" }
  = @user.name
```

The object reference syntax is a bit magical, and makes it difficult to find
where in your code a particular class attribute is defined. It is also tied
directly to the class names of the objects you pass to it, creating an
unnecessary coupling which can make refactoring your models affect your
views.

## RepeatedId

The `id` attribute [must be unique] on the page since is intended to be a unique
identifier. Repeating an `id` is an error in the HTML specification.

**Bad**
```haml
#my-id
#my-id
```

**Better**
```haml
#my-id
#my-id-2
```

[must be unique]: https://www.w3.org/TR/html5/dom.html#the-id-attribute

## RuboCop

Option         | Description
---------------|--------------------------------------------
`ignored_cops` | Array of RuboCop cops to ignore.

This linter integrates with [RuboCop](https://github.com/rubocop-hq/rubocop)
(a static code analyzer and style enforcer) to check the actual Ruby code in
your templates.

```haml
-# example.haml
- name = 'James Brown'
- unused_variable = 42

%p Hello #{name}!
```

**Output from `haml-lint`**
```
example.haml:3 [W] Useless assignment to variable - unused_variable
```

This linter will respect any RuboCop-specific configuration you have
set in your `.rubocop.yml` files, but will overwrite some configuration that
are required to format Ruby code similarly to HAML code.

Here are the [forced configurations](/config/forced_rubocop_config.yml).

You can reference to HAML files for things such as "Exclude" configuration in
your `.rubocop.yml` files just as you would for a Ruby file. So you can do
`Exclude: [foo.haml]`.

The simplest way of doing configurations for HAML would be to have a distinct
.rubocop.yml in your `view` directory.

Alternatively, you can ignored some Cop only for HamlLint using the `ignored_cop`
option to the RuboCop linter (in your `.haml-lint.yml` configuration).

You can also explicitly set which RuboCop configuration to use via the
`HAML_LINT_RUBOCOP_CONF` environment variable. This is intended to be used
by external tools which run the linter on files in temporary directories
separate from the directory where the HAML template originally resided (and
thus where the normal `.rubocop.yml` would be ignored picked up).

### Displaying Cop Names

You can display the name of the cop by adding the following to your
`.rubocop.yml` configuration:

```yaml
AllCops:
  DisplayCopNames: true
```

## RubyComments

Prefer HAML's built-in comment over ad hoc comments in Ruby code.

**Bad: Space before `#` means comment is actually treated as Ruby code**
```haml
- # A Ruby comment
```

**Good**
```haml
-# A HAML comment
```

While both comment types will result in nothing being output, HAML comments
are a little more flexible in that you can have them span multiple lines, e.g.

```haml
-# This is a multi-line
   HAML comment
```

## SpaceBeforeScript

Separate Ruby script indicators (`-`/`=`) from their code with a single space.

**Bad: no space between `=` and `some_expression`**
```haml
=some_expression
```

**Good**
```haml
= some_expression
```

**Good**
```haml
- some_value = 'Hello World'
```

Ensuring space after `-`/`=` enforces a consistency that all HAML tags/script
indicators are separated from their inline content by a space. Since it is
optional to add a space after `-`/`=` but required when writing `%tag` or
similar, the consistency is best enforced via a linter.

## SpaceInsideHashAttributes

Check the style of hash attributes against one of two possible preferred
styles, `space` (default) or `no_space`:

**Bad: inconsistent spacing inside hash attributes braces**
```haml
%tag{ foo: bar}
%tag{foo: bar }
%tag{  foo: bar }
```

**With default `space` style option: require a single space inside
hash attributes braces**
```haml
%tag{ foo: bar }
```

**With `no_space` style option: require no space inside
hash attributes braces**
```haml
%tag{foo: bar}
```

This offers the ability to ensure consistency of Haml hash
attributes style with ruby hash literal style (compare with
the Style/SpaceInsideHashLiteralBraces cop in Rubocop).

## TagName

Tag names should not contain uppercase letters.

**Bad**
```haml
%BODY
```

**Good**
```haml
%body
```

This is a _de facto_ standard in writing HAML documents as well as HTML in
general, as it is easier to type and matches the convention of many developer
tools. If you are writing HAML to output XML documents, however, it is a strict
requirement.

## TrailingEmptyLines

HAML documents should not contain empty lines at the end of the file.

## TrailingWhitespace

HAML documents should not contain trailing whitespace (spaces or tabs) on any
lines.

## UnnecessaryInterpolation

Avoid using unnecessary interpolation for inline tag content.

**Bad**
```haml
%tag #{expression}
```

**Good: more concise**
```haml
%tag= expression
```

## UnnecessaryStringOutput

Avoid outputting string expressions in Ruby when static text will suffice.

**Bad**
```haml
%tag= "Some #{interpolated} string"
```

**Good: more concise**
```haml
%tag Some #{interpolated} string
```

HAML gracefully handles string interpolation in static text, so you don't need
to work with Ruby strings in order to use interpolation.

## ViewLength

Keep view templates to a manageable length.

Large views can be split into separate partials.

Presentation logic can be extracted to a view helper, presenter or decorator.

Domain logic can be extracted to a model or service object.
