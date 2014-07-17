# HAML-Lint

[![Gem Version](https://badge.fury.io/rb/haml-lint.svg)](http://badge.fury.io/rb/haml-lint)
[![Build Status](https://travis-ci.org/causes/haml-lint.svg)](https://travis-ci.org/causes/haml-lint)
[![Code Climate](https://codeclimate.com/github/causes/haml-lint.png)](https://codeclimate.com/github/causes/haml-lint)
[![Dependency Status](https://gemnasium.com/causes/haml-lint.svg)](https://gemnasium.com/causes/haml-lint)

`haml-lint` is a tool to help keep your [HAML](http://haml.info) files
clean and readable. You can run it manually from the command-line, or integrate
it into your [SCM hooks](https://github.com/causes/overcommit). It uses rules
established by the team at [Causes.com](https://causes.com).

* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Configuration](#configuration)
* [What Gets Linted](#what-gets-linted)
* [Editor Integration](#editor-integration)
* [Git Integration](#git-integration)
* [Contributing](#contributing)
* [Changelog](#changelog)
* [License](#license)

## Requirements

 * Ruby 1.9.3+
 * HAML 4.0+

## Installation

```bash
gem install haml-lint
```

## Usage

Run `haml-lint` from the command-line by passing in a directory (or multiple
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

Command Line Flag         | Description
--------------------------|----------------------------------------------------
`-c`/`--config`           | Specify which configuration file to use
`-e`/`--exclude`          | Exclude one or more files from being linted
`-i`/`--include-linter`   | Specify which linters you specifically want to run
`-x`/`--exclude-linter`   | Specify which linters you _don't_ want to run
`-h`/`--help`             | Show command line flag documentation
`--show-linters`          | Show all registered linters
`-v`/`--version`          | Show version

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

  LineLength:
    max: 100
```

All linters have an `enabled` option which can be `true` or `false`, which
controls whether the linter is run, along with linter-specific options. The
defaults are defined in `config/default.yml`.

## What Gets Linted

`haml-lint` is an opinionated tool that helps you enforce a consistent style in
your HAML files. As an opinionated tool, we've had to make calls about what we
think are the "best" style conventions, even when there are often reasonable
arguments for more than one possible style. While all of our choices have a
rational basis, we think that the opinions themselves are less important than
the fact that `haml-lint` provides us with an automated and low-cost means of
enforcing consistency.

Any lint can be disabled by using the `--exclude-linter` flag.

### Ruby Code Analysis

`haml-lint` integrates with [RuboCop](https://github.com/bbatsov/rubocop) to
check the actual Ruby code in your templates. It will respect any
RuboCop-specific configuration you have set via `.rubocop.yml` files, but will
also explicitly ignore some checks that don't make sense in the context of HAML
(like `BlockAlignment`).

```haml
-# example.haml
- name = 'James Brown'
- unused_variable = 42

%p Hello #{name}!
```

```
example.haml:3 [W] Useless assignment to variable - unused_variable
```

### HAML Checks

* Don't write unnecessary `%div` when it would otherwise be implicit.

    ```haml
    // Incorrect - div is unnecessary when a class/ID is specified
    %div.button

    // Correct - div is required when no class/ID is specified
    %div

    // Correct
    .button
    ```

* Wrap lines at 80 characters (configurable)

    Lines longer than 80 characters are more difficult to read and are usually
    a sign of complexity.

* Don't span multiple lines using the multiline pipe (`|`) syntax.

    ```haml
    // Incorrect
    %p= 'Some' + |
        'long' + |
        'string' |

    // Correct - use helpers to generate long dynamic strings
    %p= generate_long_string

    // Correct - split long method calls on commas
    %p= some_helper_method(some_value,
                           another_value,
                           yet_another_value)

    // Correct - split attribute definitions/hashes on commas
    %p{ data: { value: value,
                name: name } }
    ```

    The multiline bar was [made awkward intentionally](http://haml.info/docs/yardoc/file.REFERENCE.html#multiline)
    by the creators of HAML. `haml-lint` takes this a step further by
    discouraging its use entirely, as it almost always suggests an
    unnecessarily complicated template that should have its logic
    extracted into a helper.

* Separate script indicators (`-`/`=`) from their code with a single space.

    ```haml
    // Incorrect - no space between `=` and `some_value`
    =some_value

    // Correct
    = some_value

    // Correct
    - some_value = 'Hello World'
    ```

* Tag names should comprise of all lowercase letters.

    ```haml
    // Incorrect
    %BODY

    // Correct
    %body
    ```

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

## Git Integration

If you'd like to integrate `haml-lint` into your Git workflow, check out our
Git hook manager, [overcommit](https://github.com/causes/overcommit).

## Contributing

We love getting feedback with or without pull requests. If you do add a new
feature, please add tests so that we can avoid breaking it in the future.

Speaking of tests, we use `rspec`, which can be run like so:

```bash
bundle exec rspec
```

## Changelog

If you're interested in seeing the changes and bug fixes between each version
of `haml-lint`, read the [HAML-Lint Changelog](CHANGELOG.md).

## License

This project is released under the MIT license.
