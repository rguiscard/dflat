const df = @cImport({
    @cInclude("dflat.h");
    @cInclude("memopad.zig.h");
});

var untitled = [_:0]u8{'U', 'n', 't', 'i', 't', 'l', 'e', 'd'};


pub fn main() !void {
    const init_value = df.init_messages();
    if (init_value == 0)
        return;

    // Argv = argv;
    // if (!LoadConfig())
    //     cfg.ScreenLines = SCREENHEIGHT;

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
    // LoadHelpFile(DFlatApplication);

    _ = df.SendMessage(wnd, df.SETFOCUS, df.TRUE, 0);

    // while (argc > 1)    {
    //     OpenPadWindow(wnd, argv[1]);
    //     --argc;
    //     argv++;
    // }

    while (df.dispatch_message() > 0) {
    }

    return;
}

// ------- window processing module for the
//                    memopad application window -----
fn MemoPadProc(wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch(msg) {
        df.COMMAND => {
            switch(p1) {
                df.ID_NEW => {
                    NewFile(wnd);
                    return df.TRUE;
                },
                df.ID_OPEN => {
                    SelectFile(wnd);
                    return df.TRUE;
                },
                else => {
                    return df.MemoPadProc(wnd, msg, p1, p2);
                }
            }
        },
        else => {
            return df.MemoPadProc(wnd, msg, p1, p2);
        }
    }
    return df.FALSE;
}

// --- The New command. Open an empty editor window ---
fn NewFile(wnd: df.WINDOW) void {
    df.OpenPadWindow(wnd, &untitled);
}

// --- The Open... command. Select a file  ---
fn SelectFile(wnd: df.WINDOW) void {
    var fspec = [_:0]u8{ '*'};
    var filename: [df.MAXPATH]u8 = undefined;

    if (df.OpenFileDialogBox(&fspec, &filename) > 0) {
        // --- see if the document is already in a window ---
        var wnd1:df.WINDOW = df.FirstWindow(wnd);
        while (wnd1 != null)    {
            if (wnd1.*.extension) |extension| {
                const ext:[*c]const u8 = @ptrCast(extension);
                if (df.strcasecmp(&filename, ext) == 0) {
                    _ = df.SendMessage(wnd1, df.SETFOCUS, df.TRUE, 0);
                    _ = df.SendMessage(wnd1, df.RESTORE, 0, 0);
                    return;
                }
            }
            _ = df.printf("not null\n");
            wnd1 = df.NextWindow(wnd1);
        }
        df.OpenPadWindow(wnd, &filename);
    }
}

const std = @import("std");

// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
// const df_lib = @import("dflat_lib");
