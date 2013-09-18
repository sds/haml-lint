# HAML-Lint

[![Gem Version](https://badge.fury.io/rb/haml-lint.png)](http://badge.fury.io/rb/haml-lint)
[![Build Status](https://travis-ci.org/causes/haml-lint.png)](https://travis-ci.org/causes/haml-lint)
[![Code Climate](https://codeclimate.com/github/causes/haml-lint.png)](https://codeclimate.com/github/causes/haml-lint)

`haml-lint` is a tool to help keep your [HAML](http://haml.info) files
clean and readable. You can run it manually from the command-line, or integrate
it into your SCM hooks. It uses rules established by the team at
[Causes.com](https://causes.com).

## Requirements

 * Ruby 1.9.3+
 * HAML 4.0.3+

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

## What gets linted

`haml-lint` is an opinionated tool that helps you enforce a consistent style in
your HAML. As an opinionated tool, we've had to make calls about what we think
are the "best" style conventions, even when there are often reasonable arguments
for more than one possible style. While all of our choices have a rational
basis, we think that the opinions themselves are less important than the fact
that `haml-lint` provides us with an automated and low-cost means of enforcing
consistency.

To get a sense of what kinds of lints exist and what they detect, check out
[the spec suite](https://github.com/causes/haml-lint/tree/master/spec/linter).

## Contributing

We love getting feedback with or without pull requests. If you do add a new
feature, please add tests so that we can avoid breaking it in the future.

Speaking of tests, we use `rspec`, which can be run like so:

```bash
bundle exec rspec
```

## See also

If you'd like to integrate `haml-lint` with Git as a pre-commit hook, check out
our Git hook gem, [overcommit](https://github.com/causes/overcommit).

## License

This project is released under the MIT license.
