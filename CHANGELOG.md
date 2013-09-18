# HAML-Lint Changelog

[![Gem Version](https://badge.fury.io/rb/haml-lint.png)](http://badge.fury.io/rb/haml-lint)
[![Code Climate](https://codeclimate.com/github/causes/haml-lint.png)](https://codeclimate.com/github/causes/haml-lint)

## master (unreleased)

* New lint `ImplicitDiv` `%div`s which are unnecessary due to a class or ID
  specified on the tag
* New lint `TagName` ensures tag names are lowercase
* Minimum version of Rubocop bumped to `0.13.0`
* New lint `MultilinePipe` ensures the pipe `|` character is never used for
  wrapping lines

## 0.1.0

* New lint `SpaceBeforeScript` ensures that Ruby code in HAML indicated with the
  `-` and `=` characters always has one space separating them from code
* New lint `RubyScript` integrates with [Rubocop](https://github.com/bbatsov/rubocop)
  to report lints supported by that tool (respecting any existing `.rubocop.yml`
  configuration)
