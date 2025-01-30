# HAML-Lint Changelog

### 0.60.0

* Run linters in parallel by default
* Update `InstanceVariables` linter to support :ruby filters

### 0.59.0

* Speed up load time by preferring `require_relative` in internal gem file loading

### 0.58.0

* Fix `block_keyword` method returning keywords used as arguments of method call

### 0.57.0

* Add `GitHubReporter`

### 0.56.0

* Rubocop: Properly pass the whitespace around tag attributes to RuboCop. This allows some improved corrections and fixes bugs.

### 0.55.0

* Lazily open files to avoid file descriptor exhaustion

### 0.54.0

* Drop support for Ruby 2.7, which reached [EoL](https://www.ruby-lang.org/en/downloads/branches/) in March 2023
* Add support for `--stdin`/`-s` flags for piping from standard input

### 0.53.0

* Drop Haml 4 compatibility
* Add support for conditional comments in `RuboCop` linter

### 0.52.0

* Add Haml 6.3 compatibility
* Add `--stderr` flag
* Fix `node_for_line` helper to return last possible node when nothing matches

### 0.51.0

* Allow Haml > 6.1

### 0.50.0

* Update minimum Ruby version to 2.7+
* Disable RuboCop's `Style/RedundantStringEscape` cop

### 0.49.3

* Fix some cases where part of multiline scripts could end up less indented than the
  starting line of that script.

### 0.49.2

* Fix handling of interpolation of plain when the plain is spread over multiple lines using pipes

### 0.49.1

* Fix handling of multiline within interpolation to not crash for auto-correct

### 0.49.0

* Add `TrailingEmptyLines` linter
* Omit warning output for Ruby parser patch version discrepancies

### 0.48.0

* Fix `Marshal.dump` error when using `--parallel` option and `RepeatedId` Linter
* Improved support for multiline code with RuboCop linting/auto-correction
* Fix handling of ==, !, &, !=, &=, !==, &==

### 0.47.0

* Bugfixes related to experimental auto-correct with RuboCop
* Fix `Marshal.dump` errors when using `--parallel` option

### 0.46.0

* Add ERB pre-processing for configuration files
* Add experimental auto-correct using RuboCop feature
* Replaced exising RuboCop Linter by a new one which should be more accurate,
  but may cause difference
* Minimum RuboCop version is now 1.0
* Add `NoPlaceholders` linter

### 0.45.0

* Add support for referencing configuration files relative to the home directory

### 0.44.0

* Add `inherit_gem` option to support loading configuration from gems

### 0.43.0

* Add support for HAML 6.1

### 0.42.0

* Add support for setting RuboCop configuration in `haml-lint.yml`
* Fix issue where `forwardable` gem requirement not loaded

### 0.41.0

* Add support for HAML 6 beta
* Fix Ruby extractor to keep newlines in certain cases

### 0.40.1

* Fix `InstanceVariables` check in multiline blocks

### 0.40.0

* Fix `SpaceInsideHashAttribute` to allow attributes across multiple lines on HAML 5.2.

### 0.39.0

* Revert change to `SpaceInsideHashAttribute` since it was not compatible across all HAML versions

### 0.38.0

* Fix config merging behavior so new empty array (the default) does not overwrite old array
* Fix `SpaceInsideHashAttribute` to allow attributes across multiple lines
* Add `OffenseCountReporter` (use by specifying `--reporter offense-count`)

### 0.37.1

* Add `Layout/ArgumentAlignment` to list of RuboCop cops ignored by default

### 0.37.0

* [#329](https://github.com/sds/haml-lint/pull/329) Improve performance by reusing `RuboCop::CLI` instance

### 0.36.0

* [#322](https://github.com/sds/haml-lint/pull/322) Add support for `--parallel` flag to run linters in parallel
* [#326](https://github.com/sds/haml-lint/pull/326) Relax `haml` gem version constraint to allow 5.2.x

### 0.35.0

* [#318](https://github.com/sds/haml-lint/pull/318) Fail HAML-Lint run when RuboCop exits unsuccessfully
* [#320](https://github.com/sds/haml-lint/pull/320) Add support for Ruby 2.7

### 0.34.2

* Update ignored cops to support cop renames introduced by RuboCop 0.79.0

### 0.34.1

* Update ignored cops to support cop renames introduced by RuboCop 0.77.0

### 0.34.0

* [#313](https://github.com/sds/haml-lint/pull/313) Remove explicit dependency on Rake, making it optional as it's only need for the Rake integration

### 0.33.0

* [#312](https://github.com/sds/haml-lint/pull/312) - Fix handling of `haml-lint:disable` directives in some cases

### 0.32.0

* [#305](https://github.com/sds/haml-lint/pull/305) - Support HAML 5.1
* [#309](https://github.com/sds/haml-lint/pull/309) - Ignore `Layout/CaseIndentation` RuboCop cop by default

### 0.31.0

* Allow HAML Lint spec helpers to be loaded with `require` in other projects

### 0.30.0

* Drop support for HAML 4.1 beta
* Fix broken Rake task regression introduced in 0.28.0

### 0.29.0

* Fix `--auto-gen-config` to allow running with an existing configuration file
* Fix `config` option for the Rake task to not be ignored
* Fix the span of multiline nodes to be more precise
* Ignore `Layout/AlignHash` cops by default
* Drop support for Ruby 2.3 or older
* Allow `ViewLength` linter to be disabled inline
* Allow comment banners in `LeadingCommentSpace` linter

### 0.28.0

* Fix `ClassAttributeWithStaticValue` to gracefully handle certain malformed
  attributes
* Add ability to include custom linters
* Drop support for Ruby 2.1
* Fix passing absolute filenames ignoring relative path excludes config

### 0.27.0

* Respect severity levels of RuboCop cops in reported lints
* Fix `--fail-level` and `--fail-fast` to work when specified together
* Fix erroneous `Layout/CommentIndentation` cop warnings for HAML multiline comments
* Update default RuboCop exclusions to handle new `Layout/ElseAlignment`,
  `Layout/EndOfLine`, `Metrics/BlockNesting`, and `Naming/FileName` cops which were
  moved to new namespaces. `Style/FinalNewline` was removed.
* Require RuboCop 0.50.0 or newer
* Drop support for Ruby 2.0 since RuboCop dropped support (Ruby 2.1+ is still supported)

### 0.26.0

* Add support for RuboCop 0.49.0+
* Require RuboCop 0.49.0+ due to breaking upstream change
* Condense generated `.haml-lint_todo.yml` file by using `enabled: false`
  for linters with lints in more than 15 files
* Fix `UnnecessaryInterpolation` linter for two-character variables
* Add `ViewLength` linter for checking whether a view has too many lines in it.

### 0.25.1

* Fix error on nodes with attributes assigned dynamically (#232)

### 0.25.0

* Add `max_consecutive` option to `ConsecutiveComments` linter
* Fix `TrailingWhitespace` linter to report correct line for multiline nodes
* Add `InlineStyles` linter to check for use of the `style` attribute
* Add support for Haml 5.0.0+

### 0.24.0

* Add new Indentation linter
* Add `--auto-gen-config` to generate a "todo-list" of offenses to fix
* Add `inherits_from` to configuration to allow reusability
* Prevent crashing when unexpected syntax is discovered

### 0.23.2

* Handle different line endings in files
* Report real line number with lint for LineLength

* Ensure RepeatedId linter resets between files

### 0.23.1

* Ensure RepeatedId linter resets between files

### 0.23.0

* Fix issue with running haml-lint on empty files
* Keep empty lines within Ruby filters

### 0.22.1

* Include `json` amongst list produced by `--show-reporters`

### 0.22.0

* Allow linters to be toggled with inline comments
* Add new `progress` reporter
* Allow linter to `--fail-fast` on first file that has a lint above the given `--fail-level`
* Add new `InstanceVariable` linter to find usage of `@instance_variable`s
* Add new `hash` reporter to make integrations with other tools simpler
* Add new `AlignmentTabs` to catch usage of tabs for alignment
* Show summary at the end when the `--summary` flag is used
* Report syntax errors as a `Syntax` linter
* Add new `IdNames` linter, checking format of `#id-strings`
* Add support for Haml 5

### 0.21.0

* Stop using temp files for RuboCop (#172)

### 0.20.0

* Update minimum RuboCop version to 0.47.0+ due to [breaking change in
  RuboCop AST interface](https://github.com/rubocop-hq/rubocop/commit/48f1637eb36)

### 0.19.0

* Relax `rake` gem constraint to allow 12.x

### 0.18.5

* Fix `SpaceBeforeScript` to not error on tags with inline scripts spanning
  multiple lines with indented vertical pipes
* Disable `Style/EndOfLine` RuboCop cop by default

### 0.18.4

* Fix `ClassesBeforeIds` output format to handle `id` EnforcedStyle option better
* Add `report_lint` RSpec matcher to test lint message

### 0.18.3

* Disable `Metrics/BlockLength` cop in `RuboCop` linter

### 0.18.2

* Fix `Checkstyle` output format to handle lints with no associated linter
* Ignore comments in `SpaceBeforeScript` linter

### 0.18.1

* Fix handling of multiline HAML comments to not pass invalid Ruby code to
  RuboCop

### 0.18.0

* Fix `RuboCop` linter's `ignored_cops` setting to not crash when empty string
* Include linter name in JSON reporter output
* Allow IDs before classes to be preferred in `ClassesBeforeIds` linter
* Respect HAML comments as Ruby code comments so RuboCop cops can be
  disabled/enabled inline via comments

### 0.17.1

* Fix `Checkstyle` output format to properly quote characters in messages

### 0.17.0

* Add `Checkstyle` output format
* Add `EmptyObjectReference` linter to report tags with empty object references

### 0.16.2

* Fix `UnnecessaryStringOutput` to not erroneously warn on lines with equal
  signs in the middle of the line
* Fix `skip_frontmatter` option to preserve line numbers

### 0.16.1

* Fix `RuboCop` linter to ignore `ElseAlignment` and
  `FrozenStringLiteralComment` cops by default

### 0.16.0

* Fix `MultilineScript` to not erroneously report `begin`/`rescue` blocks
* Fix `ClassAttributeWithStaticValue` to not erroneously report `class`
  attributes with method call or instance variable values
* Update minimum RuboCop version to 0.36.0 to fix compatibility issues with
  Astrolabe gem, switching to RuboCop's own implementation instead
* Fix `RuboCop` linter to not erroneously report
  `Style/IdenticalConditionalBranches` warnings

### 0.15.2

* Assume UTF-8 as the default encoding for all linted files

### 0.15.1

* Fix `RuboCop` linter to properly parse files containing anonymous blocks with
  trailing comments
* Fix `exclude` option to work with paths prefixed with `./`
* Fix `RuboCop` linter to not report erroneous `Style/Next` warnings for `if`
  statements in `do` blocks

### 0.15.0

* Improve bug reporting instructions in error message
* Add `Indentation` linter to enforce that spaces or tabs are used for
  indentation (enabled by default and defaults to spaces)
* Add `FinalNewline` linter to enforce the presence of a final newline
  in files
* Fix `UnnecessaryStringOutput` to gracefully handle script output with comments
* Add verbose version flag `-V/--verbose-version` to display `haml` and `ruby`
  version information in addition to output of `-v/--version` flag

### 0.14.1

* Fix bug in `UnnecessaryStringOutput` where false positives would still be
  reported for literal strings with interpolation

### 0.14.0

* Change required Ruby version from 1.9.3+ to 2.0.0+ since 1.9.3 has been EOLed
* Fix false positives in `UnnecessaryStringOutput` for strings starting with
  reserved HAML characters (where enclosing in a string is required)
* Add `severity` linter option allowing the severity of a lint to be explicitly
  specified
* Fix `RuboCop` to report correct lines for cops reported on interpolated Ruby
  code in filters

### 0.13.0

* Rename `haml-lint` gem to `haml_lint` to follow RubyGems [conventions for
  naming gems](http://guides.rubygems.org/name-your-gem/)

### 0.12.0

* Fix non-visible line number on light-colored terminal backgrounds
* Allow files without `.haml` extension to be linted when explicitly specified
* Ignore `Style/TrailingBlankLines` warnings from RuboCop by default
* Fix `RuboCop` linter to not report `Style/AlignHash` warnings for HAML code
  with 1.8-style hash rockets spanning multiple lines
* Fix `RuboCop` linter to not report `Style/EmptyElse` warnings for HAML code
  containing `if`/`else` blocks containing only HAML filters
* Add `MultilineScript` linter to report scripts with trailing operators that
  should be merged with the following line
* Add `AltText` linter to report missing `alt` attributes on `img` tags
* Fix `UnnecessaryStringOutput` to not report warnings for strings with methods
  called on them

### 0.11.0

* Fix `SpaceInsideHashAttributes` not reporting lints for implicit div tags
* Fix `RuboCop` from incorrectly reporting `Style/AsciiComments` cops for
  plain text nodes with Unicode characters
* Gracefully handle missing configuration files that are explicitly given
* Improve `HamlLint::RakeTask` to support passing a list of files as task
  arguments. (breaks existing functionality; see
  [README](README.md/#rake-integration) for details)
* Add `--[no-]color` flags allowing colored output to be explicitly set

### 0.10.0

* Fix bug where hash attributes consisting only of strings/symbols written in
  hashrocket style were not being passed to RuboCop
* Add `SpaceInsideHashAttributes` linter which enforces spaces/no spaces inside
  tag attributes
* Fix bug where the source code of tag hash attributes would be incorrectly
  extracted for hashes spanning multiple lines
* Include name of cop in lints reported by `RuboCop`
* Fix `LeadingCommentSpace` to not report lints on comments with multiple
  leading spaces

### 0.9.0

* Fix bug in `LeadingCommentSpace` where empty comment lines would incorrectly
  report lints.
* Fix bug where any `haml` version 4.0.6 or later would not remove the special
  end-of-document marker from parse trees
* Fix bug where RuboCop's `Style/OneLineConditional` cop would incorrectly be
  reported for HAML code with `if`/`else` statements
* Fix bug where RuboCop's `Style/SymbolProc` cop would incorrectly be reported

### 0.8.0

* Fix bug in `ConsecutiveSilentScripts` where control statements with nested
  HAML would incorrectly be reported as silent scripts
* Fix bug in `ImplicitDiv` where incorrect lint would be reported for `div`
  tags with dynamic ids or classes
* Fix bug in `ClassAttributeWithStaticValue` where syntax errors in attributes
  would result in a crash
* Add `TrailingWhitespace` linter which checks for whitespace at the end of a line
* Fix bug where last statement of HAML document would be removed when using
  `haml` 4.1.0.beta.1
* Fix bug where `ObjectReferenceAttributes` would incorrectly report a bug for
  all tags when using `haml` 4.1.0.beta.1

### 0.7.0

* New lint `UnnecessaryInterpolation` checks for interpolation in inline
  tag content that can be written more concisely as just the expression
* New lint 'UnnecessaryStringOutput` checks for script output of literal
  strings that could be converted to regular text content
* New lint `ClassesBeforeIds` checks that classes are listed before IDs
  in tags
* Linter name is now included in output when error/warning reported
* New lint `RubyComments` checks for comments that can be converted to
  HAML comments
* New lint `EmptyScript` checks for empty scripts (e.g. `-` followed by
  nothing)
* New lint `LeadingCommentSpace` checks for a space after the `#` in
  comments
* Fix bug where including and excluding the same linter would result in a crash
* New lint `ConsecutiveComments` checks for consecutive comments that could be
  condensed into a single multiline comment
* New lint `ConsecutiveSilentScripts` checks for consecutive lines of Ruby code
  that could be condensed into a single `:ruby` filter block
* Fix bug in Linter::UnnecessaryStringOutput when tag is empty
* Add `skip_frontmatter` option to configuration which customizes whether
  frontmatter included at the beginning of HAML files in frameworks like
  Jekyll/Middleman are ignored
* Change parse tree hierarchy to use `HamlLint::Tree::Node` subclasses instead
  of the `Haml::Parser::ParseNode` struct to make working with it easier
* New lint `ObjectReferenceAttributes` checks for the use of the object
  reference syntax to set the class/id of an element
* New lint `HtmlAttributes` checks for the use of the HTML-style attributes
  syntax when defining attributes for an element
* New lint `ClassAttributeWithStaticValue` checks for assigning static values
  for class attributes in dynamic hashes

### 0.6.1

* Add rake task integration
* Fix broken `--help` switch
* Silence `LineLength` RuboCop check
* Upgrade Rubocop dependency to >= 0.25.0

### 0.6.0

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

### 0.5.2

* Use >= 0.23.0 for RuboCop dependency

### 0.5.1

* Ignore the `Next` Rubocop cop
* Fix crash when reporting a lint inside string interpolation in a filter

### 0.5.0

* Ignore the `FileName` Rubocop cop
* Fix loading correct .rubocop.yml config

### 0.4.1

* Relax HAML dependency from `4.0.3` to `4.0`+

### 0.4.0

* Upgrade `rubocop` dependency from `0.15.0` to `0.16.0`
* Fix broken `--show-linters` flag
* Ignore `BlockAlignment`, `EndAlignment`, and `IndentationWidth` Rubocop lints
* Fix bug where `SpaceBeforeScript` linter would incorrectly report lints when
  the same substring appeared on a line underneath a tag with inline script

### 0.3.0

* Fix bug in `ScriptExtractor` where incorrect indentation would be generated
  for `:ruby` filters containing code with block keywords
* Differentiate between syntax errors and lint warnings by outputting severity
  level for lint (`E` and `W`, respectively).
* Upgrade `rubocop` dependency to `0.15.0`

### 0.2.0

* New lint `ImplicitDiv` `%div`s which are unnecessary due to a class or ID
  specified on the tag
* New lint `TagName` ensures tag names are lowercase
* Minimum version of Rubocop bumped to `0.13.0`
* New lint `MultilinePipe` ensures the pipe `|` character is never used for
  wrapping lines

### 0.1.0

* New lint `SpaceBeforeScript` ensures that Ruby code in HAML indicated with the
  `-` and `=` characters always has one space separating them from code
* New lint `RubyScript` integrates with [Rubocop](https://github.com/rubocop-hq/rubocop)
  to report lints supported by that tool (respecting any existing `.rubocop.yml`
  configuration)
