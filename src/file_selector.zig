const df = @cImport({
    @cInclude("dflat.h");
    @cInclude("file-selector.h");
});

var filename: [1024]u8 = undefined;
var dir: [1024]u8 = undefined;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    try run_dflat_app();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdErr().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var dir_it = std.mem.splitScalar(u8, &dir, 0);
    var filename_it = std.mem.splitScalar(u8, &filename, 0);

    const paths = [_][]const u8{ dir_it.first(), filename_it.first() };
    const path = try std.fs.path.join(allocator, &paths);
    try stdout.print("{s}\n", .{path});
    try bw.flush(); // Don't forget to flush!
}

fn run_dflat_app() !void {
    const init_value = df.init_messages();
    if (init_value == 0)
        return;

    const wnd = df.CreateWindow(df.APPLICATION,
                        "File Selector",
                        0, 0, -1, -1,
                        &df.MainMenu,
                        null,
                        FileSelectorProc,
                        df.MOVEABLE  |
                        df.SIZEABLE  |
                        df.HASBORDER |
                        df.MINMAXBOX |
                        df.HASSTATUSBAR
                        );
    _ = df.SendMessage(wnd, df.SETFOCUS, df.TRUE, 0);
    try SelectFile(wnd);

    while (df.dispatch_message() > 0) {
    }

    return;
}

fn SelectFile(wnd: df.WINDOW) !void {
    var fspec = [_:0]u8{ '*'};

    if (df.OpenFileDialogBox(&fspec, &filename) > 0)    {
        _ = df.getcwd(&dir, 1024);
        df.PostMessage(wnd, df.CLOSE_WINDOW, 0, 0);
    }
}

fn FileSelectorProc(wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (msg)    {
        df.COMMAND => {
            switch (p1)    {
                df.ID_OPEN => {
                    df.SelectFile(wnd);
                    return df.TRUE;
                },
                else => {
                }
            }
        },
        else => {
        }
    }
    return df.ApplicationProc(wnd, msg, p1, p2);
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const df_lib = @import("dflat_lib");
