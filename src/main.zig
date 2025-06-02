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
                        df.ApplicationProc, //MemoPadProc,
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

const std = @import("std");

// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
// const lib = @import("dflat_lib");
