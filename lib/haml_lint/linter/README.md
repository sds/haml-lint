# Linters

Below is a list of linters supported by `haml-lint`, ordered alphabetically.

* [ClassesBeforeIds](#classesbeforeids)
* [EmptyScript](#emptyscript)
* [ImplicitDiv](#implicitdiv)
* [LeadingCommentSpace](#leadingcommentspace)
* [LineLength](#linelength)
* [MultilinePipe](#multilinepipe)
* [RuboCop](#rubocop)
* [RubyComments](#rubycomments)
* [SpaceBeforeScript](#spacebeforescript)
* [TagName](#tagname)
* [UnnecessaryInterpolation](#unnecessaryinterpolation)
* [UnnecessaryStringOutput](#unnecessarystringoutput)

## ClassesBeforeIds

List classes before IDs in tags.

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
-------|--------------------------------------------------
`max`  | Maximum number of columns a single line can have.

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

## RuboCop

Option         | Description
---------------|--------------------------------------------
`ignored_cops` | Array of RuboCop cops to ignore.

This linter integrates with [RuboCop](https://github.com/bbatsov/rubocop)
(a static code analyzer and style enforcer) to check the actual Ruby code in
your templates. It will respect any RuboCop-specific configuration you have
set in `.rubocop.yml` files, but will explicitly ignore some checks that
don't make sense in the context of HAML documents (like
`Style/BlockAlignment`).

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

You can customize which RuboCop warnings you want to ignore by modifying
the `ignored_cops` option (see [`config/default.yml`](config/default.yml)
for the full list of ignored cops).

## RubyComments

Prefer HAML's built-in comment over ad hoc comments in Ruby code.

**Bad: Space after `#` means comment is actually treated as Ruby code**
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
