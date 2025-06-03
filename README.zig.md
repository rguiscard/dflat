# D-flat in Zig

The reason for porting is for practice of Zig language and for fun.

## Compilation

Currently, build the static library with zig:

```
$ zig build
```

It creats *libdflat.a* under `zig-out/lib`

Then build the memopad and other tools with Makefile which uses *zig cc*.

```
$ make
```

To run the *memopad*, 


```
$ ./memopad
```

## Examples

For a simple example, please check `src/file-selector.zig` and corresponding `file-selector.c`.
