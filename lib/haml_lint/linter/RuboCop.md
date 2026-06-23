# RuboCop integration

The `RuboCop` linter integrates with
[RuboCop](https://github.com/rubocop/rubocop) (a static code analyzer and style
enforcer) to check the actual Ruby code embedded in your templates. Rather than
running RuboCop on the `.haml` file directly, `haml-lint` reconstructs a valid
Ruby file from the Ruby fragments scattered through the template and runs RuboCop
on that — including auto-correction that is fed back into the template. See the
[Ruby extraction internals](/lib/haml_lint/ruby_extraction/README.md) if you want
to understand how that works.

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

| Option         | Description                      |
| -------------- | -------------------------------- |
| `ignored_cops` | Array of RuboCop cops to ignore. |

## Configuration

This linter respects any RuboCop-specific configuration you have set in your
`.rubocop.yml` files, but it overwrites some configuration that is required to
format Ruby code similarly to HAML code. Here are the
[forced configurations](/config/forced_rubocop_config.yml).

You can reference HAML files for things such as `Exclude` configuration in your
`.rubocop.yml` files just as you would for a Ruby file, so you can do
`Exclude: [foo.haml]`. The simplest way of configuring RuboCop for HAML is to
have a distinct `.rubocop.yml` in your `views` directory.

You can also explicitly set which RuboCop configuration to use via the
`HAML_LINT_RUBOCOP_CONF` environment variable. This is intended to be used by
external tools which run the linter on files in temporary directories separate
from the directory where the HAML template originally resided (and thus where the
normal `.rubocop.yml` would not be picked up).

## Disabling a cop for HAML files

Because the [forced configurations](/config/forced_rubocop_config.yml) always
take precedence over your `.rubocop.yml`, setting `Enabled: false` there for a
forced cop (such as `Layout/CaseIndentation`) has **no effect**. To turn such a
cop off for HAML files, use the `ignored_cops` option of the RuboCop linter in
your `.haml-lint.yml`:

```yaml
linters:
  RuboCop:
    ignored_cops:
      - Layout/CaseIndentation
```

This passes the cops to RuboCop via `--except`, so they are skipped entirely
(both when reporting and when auto-correcting), regardless of the forced
configuration. The same option also works for any non-forced cop you want to
ignore only for HAML.

## Known false positives with Rails cops

When you use [rubocop-rails](https://github.com/rubocop/rubocop-rails), some
`Rails/*` cops assume they are running inside a controller or model and report
offenses that do not apply to view code. Because `haml-lint` runs RuboCop on the
Ruby extracted from your templates, these cops can fire — and "fixing" them may
introduce bugs. A couple of known cases:

- **`Rails/FindEach`** — flags `each` on an ActiveRecord relation and suggests
  `find_each`. In a view the collection has usually already been ordered (in the
  controller, a scope, or a default scope), and `find_each` ignores ordering: it
  loads records in batches ordered by primary key. Applying the correction
  silently changes the order in which records are rendered.

  ```haml
  %ul
    - @cities.includes(:country).each do |city|
      %li #{city} (#{city.country})
  ```

  ```
  test.haml:2 [W] RuboCop: Rails/FindEach: Use `find_each` instead of `each`.
  ```

- **`Rails/HttpStatus`** — interprets a `status:` keyword as an HTTP status code,
  so `= render 'partial', status: 'future'` is reported as
  `Prefer nil over future to define HTTP status code.` even though `status` here
  is just a local passed to the partial.

Since you control which cops run (by loading `rubocop-rails` and enabling them),
the recommended fix is to disable the offending cop for HAML files. You can use
the `ignored_cops` option described above:

```yaml
linters:
  RuboCop:
    ignored_cops:
      - Rails/FindEach
      - Rails/HttpStatus
```

or scope it from your `.rubocop.yml` with an `Exclude` on `.haml` files:

```yaml
Rails/FindEach:
  Exclude:
    - "**/*.haml"
```

This list is not exhaustive — any cop that relies on controller/model context
may behave the same way in views.

## Displaying cop names

You can display the name of the cop by adding the following to your
`.rubocop.yml` configuration:

```yaml
AllCops:
  DisplayCopNames: true
```
