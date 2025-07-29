const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // Common flags used by dflat
    const flags = [_][]const u8{"-DMACOS=1",
                                "-DBUILD_FULL_DFLAT",
                                "-g",
                                "-Wno-pointer-sign",
                                "-Wno-compare-distinct-pointer-types",
                                "-Wno-invalid-source-encoding"};

    // This creates a "module", which represents a collection of source files alongside
    // some compilation options, such as optimization mode and linked system libraries.
    // Every executable or library we compile will be based on one or more modules.
    const lib_mod = b.createModule(.{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = null,
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    lib_mod.addCSourceFiles(.{ .files = &.{
            "message.c",
            "keys.c",
            "config.c",
            "dfalloc.c",
            "window.c",
            "rect.c",
            "lists.c",
            "normal.c",
            "textbox.c",
            "menubar.c",
            "menu.c",
            "popdown.c",
            "listbox.c",
            "editbox.c",
            "editor.c",
            "sysmenu.c",

            "dialbox.c",
            "text.c",
            "checkbox.c",
            "radio.c",
            "spinbutt.c",
            "combobox.c",
            "direct.c",
            "pictbox.c",
            "clipbord.c",
            "helpbox.c",
            "decomp.c",

            "video.c",
            "events-unix.c",
            "mouse-ansi.c",
            "console-unix.c",
            "kcp437.c",
            "runes.c",
            "unikey.c",
            "tty.c",
            "tty-cp437.c",
            "runshell.c",

            "dialogs.c", // this should belong to library
        },
        .flags = &flags,
    });
    lib_mod.addIncludePath(b.path("."));

    // Now, we will create a static library based on the module we created above.
    // This creates a `std.Build.Step.Compile`, which is the build step responsible
    // for actually invoking the compiler.
//    const lib = b.addLibrary(.{
//        .linkage = .static,
//        .name = "dflat",
//        .root_module = lib_mod,
//    });
//    lib.linkLibC();
//    lib.installHeader(b.path("dflat.h"), "dflat.h");
//    lib.installHeader(b.path("system.h"), "system.h");
//    lib.installHeader(b.path("dflatmsg.h"), "dflatmsg.h");
//    lib.installHeader(b.path("classes.h"), "classes.h");
//    lib.installHeader(b.path("config.h"), "config.h");
//    lib.installHeader(b.path("rect.h"), "rect.h");
//    lib.installHeader(b.path("keys.h"), "keys.h");
//    lib.installHeader(b.path("unikey.h"), "unikey.h");
//    lib.installHeader(b.path("commands.h"), "commands.h");
//    lib.installHeader(b.path("dialbox.h"), "dialbox.h");
//    lib.installHeader(b.path("helpbox.h"), "helpbox.h");
//    lib.installHeader(b.path("video.h"), "video.h");
//    lib.installHeader(b.path("classdef.h"), "classdef.h");
//    lib.installHeader(b.path("menu.h"), "menu.h");

    // This declares intent for the library to be installed into the standard
    // location when the user invokes the "install" step (the default step when
    // running `zig build`).
//    b.installArtifact(lib);

    // memopad (exe) import lib_mod as module while file-selector links libdflat.a

    const memopad_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    memopad_mod.addCSourceFiles(.{ .files = &.{
            "memopad.zig.c",
        },
        .flags = &flags,
    });
    memopad_mod.addIncludePath(b.path("."));

    // We will also create a module for our other entry point, 'main.zig'.
    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addIncludePath(b.path("."));

    // Modules can depend on one another using the `std.Build.Module.addImport` function.
    // This is what allows Zig source code to use `@import("foo")` where 'foo' is not a
    // file path. In this case, we set up `exe_mod` to import `lib_mod`.
    exe_mod.addImport("dflat", lib_mod); // this import c as module
    exe_mod.addImport("memopad", memopad_mod);

    // This creates another `std.Build.Step.Compile`, but this one builds an executable
    // rather than a static library.
    const exe = b.addExecutable(.{
        .name = "memopad",
        .root_module = exe_mod,
    });
    exe.linkLibC();
    exe.addIncludePath(b.path("."));

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // File selector
    const fs_mod = b.createModule(.{
        .root_source_file = b.path("examples/file_selector.zig"),
        .target = target,
        .optimize = optimize,
    });
    fs_mod.addIncludePath(b.path("."));
    fs_mod.addCSourceFiles(.{ .files = &.{
            "examples/file-selector.zig.c",
        },
        .flags = &flags,
    });
    fs_mod.addImport("dflat", lib_mod); // this import c as module
    fs_mod.addImport("memopad", memopad_mod);

    const fs_exe = b.addExecutable(.{
        .name = "file-selector",
        .root_module = fs_mod,
    });
    fs_exe.linkLibC();
    fs_exe.addIncludePath(b.path("."));

//    b.installArtifact(fs_exe);

    const run_fs = b.addRunArtifact(fs_exe);
    run_fs.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_fs.addArgs(args);
    }
    const run_fs_step = b.step("file-select", "Run file selector");
    run_fs_step.dependOn(&run_fs.step);

    // Demo to test various components
    const demo_mod = b.createModule(.{
        .root_source_file = b.path("examples/demo.zig"),
        .target = target,
        .optimize = optimize,
    });
    demo_mod.addIncludePath(b.path("."));
    demo_mod.addCSourceFiles(.{ .files = &.{
            "examples/demo.zig.c",
        },
        .flags = &flags,
    });
    demo_mod.addImport("dflat", lib_mod); // this import c as module
    demo_mod.addImport("memopad", memopad_mod);

    const demo = b.addExecutable(.{
        .name = "demo",
        .root_module = demo_mod,
    });
    demo.linkLibC();
    demo.addIncludePath(b.path("."));

//    b.installArtifact(demo);

    const run_demo = b.addRunArtifact(demo);
    run_demo.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_demo.addArgs(args);
    }
    const run_demo_step = b.step("demo", "Run demo");
    run_demo_step.dependOn(&run_demo.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });

    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
