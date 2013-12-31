# HAML-Lint Changelog

## master (unreleased)

* Upgrade `rubocop` dependency from `0.15.0` to `0.16.0`
* Fix broken `--show-linters` flag
* Ignore `BlockAlignment`, `EndAlignment`, and `IndentationWidth` Rubocop lints
* Fix bug where `SpaceBeforeScript` linter would incorrectly report lints when
  the same substring appeared on a line underneath a tag with inline script

## 0.3.0

* Fix bug in `ScriptExtractor` where incorrect indentation would be generated
  for `:ruby` filters containing code with block keywords
* Differentiate between syntax errors and lint warnings by outputting severity
  level for lint (`E` and `W`, respectively).
* Upgrade `rubocop` dependency to `0.15.0`

## 0.2.0

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
