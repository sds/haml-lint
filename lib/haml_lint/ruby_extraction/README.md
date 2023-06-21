Not supported: Tag with a multiline script
```haml
%tag= foo(bar: 42,
          abc: 123)
```
This is barely supported by Haml and has lots of edge-cases because Haml
considers that spacing to be indentation... Just extract the script to
its own line (you can keep the multi-line), which is properly handled by Haml.
