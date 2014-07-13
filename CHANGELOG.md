# HAML-Lint Changelog

## master (unreleased)

* Fix crash when reporting a lint from Rubocop that did not include a line
  number
* Allow `haml-lint` to be configured via YAML file, either by automatically
  loading `.haml-lint.yml` if it exists, or via a configuration file
  explicitly passed in via the `--config` flag
* Update RuboCop dependency to >= 0.24.1
* Rename `RubyScript` linter to `RuboCop`
* Add customizable `LineLength` linter to check that the number of columns on
  each line in a file is no greater than some maximum amount (80 by default)
* Gracefully handle invalid file paths and return semantic error code

## 0.5.2

* Use >= 0.23.0 for RuboCop dependency

## 0.5.1

* Ignore the `Next` Rubocop cop
* Fix crash when reporting a lint inside string interpolation in a filter

## 0.5.0

* Ignore the `FileName` Rubocop cop
* Fix loading correct .rubocop.yml config

## 0.4.1

* Relax HAML dependency from `4.0.3` to `4.0`+

## 0.4.0

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
