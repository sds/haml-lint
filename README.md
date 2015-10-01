# HAML-Lint

[![Gem Version](https://badge.fury.io/rb/haml_lint.svg)](http://badge.fury.io/rb/haml_lint)
[![Build Status](https://travis-ci.org/brigade/haml-lint.svg)](https://travis-ci.org/brigade/haml-lint)
[![Code Climate](https://codeclimate.com/github/brigade/haml-lint.png)](https://codeclimate.com/github/brigade/haml-lint)
[![Coverage Status](https://coveralls.io/repos/brigade/haml-lint/badge.svg)](https://coveralls.io/r/brigade/haml-lint)
[![Dependency Status](https://gemnasium.com/brigade/haml-lint.svg)](https://gemnasium.com/brigade/haml-lint)
[![Inline docs](http://inch-ci.org/github/brigade/haml-lint.svg?branch=master)](http://inch-ci.org/github/brigade/haml-lint)

`haml-lint` is a tool to help keep your [HAML](http://haml.info) files
clean and readable. In addition to HAML-specific style and lint checks, it
integrates with [RuboCop](https://github.com/bbatsov/rubocop) to bring its
powerful static analysis tools to your HAML documents.

You can run `haml-lint` manually from the command line, or integrate it into
your [SCM hooks](https://github.com/brigade/overcommit).

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

 * Ruby 2.0.0+
 * HAML 4.0+

## Installation

```bash
gem install haml_lint
```

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

Command Line Flag         | Description
--------------------------|----------------------------------------------------
`-c`/`--config`           | Specify which configuration file to use
`-e`/`--exclude`          | Exclude one or more files from being linted
`-i`/`--include-linter`   | Specify which linters you specifically want to run
`-x`/`--exclude-linter`   | Specify which linters you _don't_ want to run
`-r`/`--reporter`         | Specify which reporter you want to use to generate the output
`--[no-]color`            | Whether to output in color
`--show-linters`          | Show all registered linters
`--show-reporters`        | Display available reporters
`-h`/`--help`             | Show command line flag documentation
`-v`/`--version`          | Show `haml-lint` version
`-V`/`--verbose-version`  | Show `haml-lint`, `haml`, and `ruby` version information

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

## Linters

### [» Linters Documentation](lib/haml_lint/linter/README.md)

`haml-lint` is an opinionated tool that helps you enforce a consistent style in
your HAML files. As an opinionated tool, we've had to make calls about what we
think are the "best" style conventions, even when there are often reasonable
arguments for more than one possible style. While all of our choices have a
rational basis, we think that the opinions themselves are less important than
the fact that `haml-lint` provides us with an automated and low-cost means of
enforcing consistency.

## Editor Integration

### Vim

If you use `vim`, you can have `haml-lint` automatically run against your HAML
files after saving by using the
[Syntastic](https://github.com/scrooloose/syntastic) plugin. If you already
have the plugin, just add `let g:syntastic_haml_checkers = ['haml_lint']` to
your `.vimrc`.

### Sublime Text 3

If you use `SublimeLinter 3` with `Sublime Text 3` you can install the
[SublimeLinter-haml-lint](https://github.com/jeroenj/SublimeLinter-contrib-haml-lint)
plugin using [Package Control](https://sublime.wbond.net).

### Atom

If you use `atom`, you can install the [linter-haml](https://atom.io/packages/linter-haml) plugin.

## Git Integration

If you'd like to integrate `haml-lint` into your Git workflow, check out our
Git hook manager, [overcommit](https://github.com/brigade/overcommit).

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

[Code documentation]: http://rdoc.info/github/brigade/haml-lint/master/frames
[YARD]: http://yardoc.org/
[RubyDoc.info]: http://rdoc.info/

## Contributing

We love getting feedback with or without pull requests. If you do add a new
feature, please add tests so that we can avoid breaking it in the future.

Speaking of tests, we use `rspec`, which can be run by executing the following
from the root directory of the repository:

```bash
bundle exec rspec
```

## Community

All major discussion surrounding HAML-Lint happens on the
[GitHub issues page](https://github.com/brigade/haml-lint/issues).

You can also follow [@haml_lint on Twitter](https://twitter.com/haml_lint).

## Changelog

If you're interested in seeing the changes and bug fixes between each version
of `haml-lint`, read the [HAML-Lint Changelog](CHANGELOG.md).

## License

This project is released under the [MIT license](MIT-LICENSE).
