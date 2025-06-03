const df = @cImport({
    @cInclude("dflat.h");
});

pub fn main() !void {
    const init_value = df.init_messages();
    if (init_value == 0)
        return;

    const wnd = df.CreateWindow(df.APPLICATION,
                        "D-Flat MemoPad",
                        0, 0, -1, -1,
                        &df.MainMenu,
                        null,
                        MemoPadProc,
                        df.MOVEABLE  |
                        df.SIZEABLE  |
                        df.HASBORDER |
                        df.MINMAXBOX |
                        df.HASSTATUSBAR
                        );
    _ = df.SendMessage(wnd, df.SETFOCUS, df.TRUE, 0);

    while (df.dispatch_message() > 0) {
    }

    return;
}

fn MemoPadProc(wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    return df.ApplicationProc(wnd, msg, p1, p2);
}

const std = @import("std");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const df_lib = @import("dflat_lib");
