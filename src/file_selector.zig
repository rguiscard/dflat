const df = @cImport({
    @cInclude("dflat.h");
    @cInclude("file-selector.h");
});

pub fn main() !void {
//    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
//    const allocator = gpa.allocator();

//    var buffer: [100]u8 = undefined;
//    const buf = buffer[0..];
//    const value = df_lib.add(1,2);
//    const result = try std.fmt.bufPrintZ(buf, "D-Flat MemoPad {d}", .{value});

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
//    _ = df.SelectFile(wnd);
    try SelectFile(wnd);

    while (df.dispatch_message() > 0) {
    }

    return;
}

fn SelectFile(wnd: df.WINDOW) !void {
    var buffer: [100]u8 = undefined;
    const buf = buffer[0..];
    const result = try std.fmt.bufPrintZ(buf, "*", .{});

    var filename: [1024]u8 = undefined;
    var dir: [1024]u8 = undefined;
    if (df.OpenFileDialogBox(result.ptr, &filename) > 0)    {
        _ = df.getcwd(&dir, 1024);
        _ = df.printf("filename %s %s\n", &dir, &filename);
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
