This folder contains examples of how the RubyExtraction mechanism and the
Rubocop linter behave.

Here is how the *_examples.txt files works:

### Examples
Examples start with a `!!!` followed by the name. Every following the `!!!`
and until the next `!!!` is part of that example.

Any content before the first `!!!` is expected to be comments and is ignored.

### Comments
`!#` is a comment. If a line only has such a comment, the whole line is
removed before being passed through to the test. Otherwise, the `!# ` and
everything after is removed.

### Steps
The examples are in 4 steps:
1) input haml
2) extracted ruby
3) the corrected ruby (by rubocop)
4) the corrected haml
Each steps is delimited by a line with ---

If an example's steps contains the ^ character, it will be executed twice:
* once with the ^ replaced by -, the ^^ removed and the %% are removed
* once with the ^ replaced by =, the ^^ replaces by the special prefix
  used by haml-lint in the ruby code to handle = scripts,
  and the %% replaced by as many spaces as takes (to indent multi-line scripts)
This way, the same examples can be reused for silent and non-silent scripts.

### ERB
The files are passed through erb for cases where that is useful.

### Placeholders
TODO

### Markers
TODO

### RuboCop stubbing
Use {% rubocop_version <= '1.13' %} in the name (besides the !!!) to indicate
the required version of RuboCop for that example.

If the current Rubocop doesn't meet the version, RuboCop will not be run.
Instead, the code will consider that RuboCop returned the content of the
step 3 (the corrected ruby), this way the RuboCop linter can still do its
thing on the expected ruby code.

### Source map
Finally, for the source_map, which is also tested by this system, the information
is placed at the end of lines in the 2nd step (The extracted ruby step)

The associated line number from the 1st step (input haml) is placed at the
end of the lines in the 2nd step, prefixed by `$$`.

Whitespace before the `$$` is removed.

The line number is kept for following lines if not overwritten by another `$$`.
This reduced noise, as the line must only be specified when it changes.

The first line is automatically considered to be `$$1` unless specified otherwise.

Here is a complex example (only the first 2 steps):
```
%tag{:bar =>  123,
     :hello =>  42}
  = spam(:bing =>  512)
---
begin
  haml_lint_tag_placeholder
  haml_lint_marker_3
  WW(:bar =>  123,
     :hello =>  42) $$2
  haml_lint_marker_6
  haml_lint_marker_7 $$3
  HL.out = spam(:bing =>  512)
  haml_lint_marker_9
ensure
  HL.noop
end
```
