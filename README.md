# HAML-Lint

[![Gem Version](https://badge.fury.io/rb/haml_lint.svg)](http://badge.fury.io/rb/haml_lint)
[![Build Status](https://travis-ci.org/sds/haml-lint.svg?branch=master)](https://travis-ci.org/sds/haml-lint)
[![Maintainability](https://api.codeclimate.com/v1/badges/b1f81df6b0922ff5bcdd/maintainability)](https://codeclimate.com/github/sds/haml-lint/maintainability)
[![Coverage Status](https://coveralls.io/repos/sds/haml-lint/badge.svg)](https://coveralls.io/r/sds/haml-lint)
[![Inline docs](http://inch-ci.org/github/sds/haml-lint.svg?branch=master)](http://inch-ci.org/github/sds/haml-lint)

`haml-lint` is a tool to help keep your [HAML](http://haml.info) files
clean and readable. In addition to HAML-specific style and lint checks, it
integrates with [RuboCop](https://github.com/bbatsov/rubocop) to bring its
powerful static analysis tools to your HAML documents.

You can run `haml-lint` manually from the command line, or integrate it into
your [SCM hooks](https://github.com/sds/overcommit).

* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Configuration](#configuration)
* [Linters](#linters)
* [Editor Integration](#editor-integration)
* [Git Integration](#git-integration)
* [Rake Integration](#rake-integration)
* [Documentation](#documentation)
* [Contributing](#contributing)
* [Community](#community)
* [Changelog](#changelog)
* [License](#license)

## Requirements

 * Ruby 2.4+
 * HAML 4.0+

## Installation

```bash
gem install haml_lint
```

If you'd rather install `haml-lint` using `bundler`, don't `require` it in your `Gemfile`:

```ruby
gem 'haml_lint', require: false
```

Then you can still use `haml-lint` from the command line, but its source code won't be auto-loaded inside your application.

## Usage

Run `haml-lint` from the command line by passing in a directory (or multiple
directories) to recursively scan:

```bash
haml-lint app/views/
```

You can also specify a list of files explicitly:

```bash
haml-lint app/**/*.html.haml
```

`haml-lint` will output any problems with your HAML, including the offending
filename and line number.

### File Encoding

`haml-lint` assumes all files are encoded in UTF-8.

### Command Line Flags

Command Line Flag          | Description
---------------------------|----------------------------------------------------
`--auto-gen-config`        | Generate a configuration file acting as a TODO list
`--auto-gen-exclude-limit` | Number of failures to allow in the TODO list before the entire rule is excluded
`-c`/`--config`            | Specify which configuration file to use
`-e`/`--exclude`           | Exclude one or more files from being linted
`-i`/`--include-linter`    | Specify which linters you specifically want to run
`-x`/`--exclude-linter`    | Specify which linters you _don't_ want to run
`-r`/`--reporter`          | Specify which reporter you want to use to generate the output
`--fail-fast`              | Specify whether to fail after the first file with lint
`--fail-level`             | Specify the minimum severity (warning or error) for which the lint should fail
`--[no-]color`             | Whether to output in color
`--[no-]summary`           | Whether to output a summary in the default reporter
`--show-linters`           | Show all registered linters
`--show-reporters`         | Display available reporters
`-h`/`--help`              | Show command line flag documentation
`-v`/`--version`           | Show `haml-lint` version
`-V`/`--verbose-version`   | Show `haml-lint`, `haml`, and `ruby` version information

## Configuration

`haml-lint` will automatically recognize and load any file with the name
`.haml-lint.yml` as a configuration file. It loads the configuration based on
the directory `haml-lint` is being run from, ascending until a configuration
file is found. Any configuration loaded is automatically merged with the
default configuration (see `config/default.yml`).

Here's an example configuration file:

```yaml
linters:
  ImplicitDiv:
    enabled: false
    severity: error

  LineLength:
    max: 100
```

All linters have an `enabled` option which can be `true` or `false`, which
controls whether the linter is run, along with linter-specific options. The
defaults are defined in [`config/default.yml`](config/default.yml).

### Linter Options

Option        | Description
--------------|----------------------------------------------------------------
`enabled`     | If `false`, this linter will never be run. This takes precedence over any other option.
`include`     | List of files or glob patterns to scope this linter to. This narrows down any files specified via the command line.
`exclude`     | List of files or glob patterns to exclude from this linter. This excludes any files specified via the command line or already filtered via the `include` option.
`severity`    | The severity of the linter. External tools consuming `haml-lint` output can use this to determine whether to warn or error based on the lints reported.

### Global File Exclusion

The `exclude` global configuration option allows you to specify a list of files
or glob patterns to exclude from all linters. This is useful for ignoring
third-party code that you don't maintain or care to lint. You can specify a
single string or a list of strings for this option.

### Skipping Frontmatter

Some static blog generators such as [Jekyll](http://jekyllrb.com/) include
leading frontmatter to the template for their own tracking purposes.
`haml-lint` allows you to ignore these headers by specifying the
`skip_frontmatter` option in your `.haml-lint.yml` configuration:

```yaml
skip_frontmatter: true
```

### Inheriting from Other Configuration Files

The `inherits_from` global configuration option allows you to specify an
inheritance chain for a configuration file. It accepts either a scalar value of
a single file name or a vector of multiple files to inherit from. The inherited
files are resolved in a first in, first out order and with "last one wins"
precedence. For example:

```yaml
inherits_from:
  - .shared_haml-lint.yml
  - .personal_haml-lint.yml
```

First, the default configuration is loaded. Then the `.shared_haml-lint.yml`
configuration is loaded, followed by `.personal_haml-lint.yml`. Each of these
overwrite each other in the event of a collision in configuration value. Once
the inheritance chain is resolved, the base configuration is loaded and applies
its rules to overwrite any in the intermediate configuration.

Lastly, in order to match your RuboCop configuration style, you can also use the
`inherit_from` directive, which is an alias for `inherits_from`.

## Linters

### [» Linters Documentation](lib/haml_lint/linter/README.md)

`haml-lint` is an opinionated tool that helps you enforce a consistent style in
your HAML files. As an opinionated tool, we've had to make calls about what we
think are the "best" style conventions, even when there are often reasonable
arguments for more than one possible style. While all of our choices have a
rational basis, we think that the opinions themselves are less important than
the fact that `haml-lint` provides us with an automated and low-cost means of
enforcing consistency.

### Custom Linters

Add the following to your configuration file:

```yaml
require:
  - './relative/path/to/my_first_linter.rb'
  - 'absolute/path/to/my_second_linter.rb'
```

The files that are referenced by this config should have the following structure:

```ruby
module HamlLint
  # MyFirstLinter is the name of the linter in this example, but it can be anything
  class Linter::MyFirstLinter < Linter
    include LinterRegistry

    def visit_tag
      return unless node.tag_name == 'div'
      record_lint(node, "You're not allowed divs!")
    end
  end
end
```

For more information on the different types on HAML node, please look through
the HAML parser code: https://github.com/haml/haml/blob/master/lib/haml/parser.rb

Keep in mind that by default your linter will be disabled by default. So you
will need to enable it in your configuration file to have it run.

## Disabling Linters within Source Code

One or more individual linters can be disabled locally in a file by adding
a directive comment. These comments look like the following:

```haml
-# haml-lint:disable AltText, LineLength
[...]
-# haml-lint:enable AltText, LineLength
```

You can disable *all* linters for a section with the following:

```haml
-# haml-lint:disable all
```

### Directive Scope

A directive will disable the given linters for the scope of the block. This
scope is inherited by child elements and sibling elements that come after the
comment. For example:

```haml
-# haml-lint:disable AltText
#content
  %img#will-not-show-lint-1{ src: "will-not-show-lint-1.png" }
  -# haml-lint:enable AltText
  %img#will-show-lint-1{ src: "will-show-lint-1.png" }
  .sidebar
    %img#will-show-lint-2{ src: "will-show-lint-2.png" }
%img#will-not-show-lint-2{ src: "will-not-show-lint-2.png" }
```

The `#will-not-show-lint-1` image on line 2 will not raise an `AltText` lint
because of the directive on line 1. Since that directive is at the top level of
the tree, it applies everywhere.

However, on line 4, the directive enables the `AltText` linter for the remainder
of the `#content` element's content. This means that the `#will-show-lint-1`
image on line 5 will raise an `AltText` lint because it is a sibling of the
enabling directive that appears later in the `#content` element. Likewise, the
`#will-show-lint-2` image on line 7 will raise an `AltText` lint because it is
a child of a sibling of the enabling directive.

Lastly, the `#will-not-show-lint-2` image on line 8 will not raise an `AltText`
lint because the enabling directive on line 4 exists in a separate element and
is not a sibling of the it.

### Directive Precedence

If there are multiple directives for the same linter in an element, the last
directive wins. For example:

```haml
-# haml-lint:enable AltText
%p Hello, world!
-# haml-lint:disable AltText
%img#will-not-show-lint{ src: "will-not-show-lint.png" }
```

There are two conflicting directives for the `AltText` linter. The first one
enables it, but the second one disables it. Since the disable directive came
later, the `#will-not-show-lint` element will not raise an `AltText` lint.

You can use this functionality to selectively enable directives within a file by
first using the `haml-lint:disable all` directive to disable all linters in the
file, then selectively using `haml-lint:enable` to enable linters one at a time.

## Onboarding Onto a Preexisting Project

Adding a new linter into a project that wasn't previously using one can be
a daunting task. To help ease the pain of starting to use Haml-Lint, you can
generate a configuration file that will exclude all linters from reporting lint
in files that currently have lint. This gives you something similar to a to-do
list where the violations that you had when you started using Haml-Lint are
listed for you to whittle away, but ensuring that any views you create going
forward are properly linted.

To use this functionality, call Haml-Lint like:

    haml-lint --auto-gen-config

This will generate a `.haml-lint_todo.yml` file that contains all existing lint
as exclusions. You can then add `inherits_from: .haml-lint_todo.yml` to your
`.haml-lint.yml` configuration file to ensure these exclusions are used whenever
you call `haml-lint`.

By default, any rules with more than 15 violations will be disabled in the todo-file.
You can increase this limit with the `auto-gen-exclude-limit` option:

    haml-lint --auto-gen-config --auto-gen-exclude-limit 100


## Editor Integration

### Vim

If you use `vim`, you can have `haml-lint` automatically run against your HAML
files after saving by using the
[Syntastic](https://github.com/scrooloose/syntastic) plugin. If you already
have the plugin, just add `let g:syntastic_haml_checkers = ['haml_lint']` to
your `.vimrc`.

### Vim 8 / Neovim

If you use `vim` 8+ or `Neovim`, you can have `haml-lint` automatically run against your HAML files as you type by using the [Asynchronous Lint Engine (ALE)](https://github.com/w0rp/ale) plugin. ALE will automatically lint your HAML files if it detects `haml-lint` in your `PATH`.

### Sublime Text 3

If you use `SublimeLinter 3` with `Sublime Text 3` you can install the
[SublimeLinter-haml-lint](https://github.com/jeroenj/SublimeLinter-contrib-haml-lint)
plugin using [Package Control](https://sublime.wbond.net).

### Atom

If you use `atom`, you can install the [linter-haml](https://atom.io/packages/linter-haml) plugin.

### TextMate 2

If you use `TextMate 2`, you can install the [Haml-Lint.tmbundle](https://github.com/jjuliano/Haml-Lint.tmbundle) bundle.

### Visual Studio Code

If you use `Visual Studio Code`, you can install the [Haml Lint](https://marketplace.visualstudio.com/items?itemName=aki77.haml-lint) extension

## Git Integration

If you'd like to integrate `haml-lint` into your Git workflow, check out our
Git hook manager, [overcommit](https://github.com/sds/overcommit).

## Rake Integration

To execute `haml-lint` via a [Rake](https://github.com/ruby/rake) task, add the
following to your `Rakefile`:

```ruby
require 'haml_lint/rake_task'

HamlLint::RakeTask.new
```

By default, when you execute `rake haml_lint`, the above configuration is
equivalent to running `haml-lint .`, which will lint all `.haml` files in the
current directory and its descendants.

You can customize your task by writing:

```ruby
require 'haml_lint/rake_task'

HamlLint::RakeTask.new do |t|
  t.config = 'custom/config.yml'
  t.files = ['app/views', 'custom/*.haml']
  t.quiet = true # Don't display output from haml-lint to STDOUT
end
```

You can also use this custom configuration with a set of files specified via
the command line:

```
# Single quotes prevent shell glob expansion
rake 'haml_lint[app/views, custom/*.haml]'
```

Files specified in this manner take precedence over the task's `files`
attribute.

## Documentation

[Code documentation] is generated with [YARD] and hosted by [RubyDoc.info].

[Code documentation]: http://rdoc.info/github/sds/haml-lint/master/frames
[YARD]: http://yardoc.org/
[RubyDoc.info]: http://rdoc.info/

## Contributing

We love getting feedback with or without pull requests. If you do add a new
feature, please add tests so that we can avoid breaking it in the future.

Speaking of tests, we use [Appraisal] to test against both HAML 4 and 5. We use
`rspec` to write our tests. To run the test suite, execute the following from
the root directory of the repository:

```bash
appraisal bundle install
appraisal bundle exec rspec
```

[Appraisal]: https://github.com/thoughtbot/appraisal

## Community

All major discussion surrounding HAML-Lint happens on the
[GitHub issues page](https://github.com/sds/haml-lint/issues).

## Changelog

If you're interested in seeing the changes and bug fixes between each version
of `haml-lint`, read the [HAML-Lint Changelog](CHANGELOG.md).

## License

This project is released under the [MIT license](MIT-LICENSE).
