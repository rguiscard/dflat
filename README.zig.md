# D-flat in Zig

The reason for porting is for practice of Zig language and for fun.

## Compilation

Currently, build the static library with zig:

```
$ zig build
```

It creats *libdflat.a* under `zig-out/lib`

It also creates *memopad* under `zig-out/bin` as original executable. Run it with

`
$ zig build run
`

## Examples

For a simple example, please check `src/file-selector.zig` and corresponding `file-selector.c`.

It is also built with `zig build`.

`
$ zig build file-select
`

It will output selected file with path to stderr, which can be used with other unix tool.

For example, this will print the selected file:

`
$ zig build file-select 2> >(xargs cat)
`

The output path will be piped to `xargs cat` which will print the content via `cat` command.
