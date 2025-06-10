const df = mp.df;

var untitled = [_:0]u8{'U', 'n', 't', 'i', 't', 'l', 'e', 'd'};
const sUntitled = "Untitled";
var wndpos: c_int = 0;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    if (mp.msg.init_messages() == false)
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

    const win = mp.Window.init(wnd);

    // LoadHelpFile(DFlatApplication);

    _ = mp.msg.SendMessage(win, df.SETFOCUS, df.TRUE, 0);

    // while (argc > 1)    {
    //     OpenPadWindow(wnd, argv[1]);
    //     --argc;
    //     argv++;
    // }

    while (mp.msg.dispatch_message()) {
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
                    if (SelectFile(wnd)) {
                        return df.TRUE;
                    } else |_| {
                        return df.FALSE;
                    }
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
    OpenPadWindow(wnd, sUntitled);
}

// --- The Open... command. Select a file  ---
fn SelectFile(wnd: df.WINDOW) !void {
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
            wnd1 = df.NextWindow(wnd1);
        }

        var filename_it = std.mem.splitScalar(u8, &filename, 0);
        const Fname = filename_it.first();
        OpenPadWindow(wnd, Fname);
    }
}

// --- open a document window and load a file ---
fn OpenPadWindow(wnd: df.WINDOW, filename: []const u8) void {
    const fname = filename;
    if (std.mem.eql(u8, sUntitled, fname) == false) {
        // check for existing
        if (std.fs.cwd().access(fname, .{.mode = .read_only})) {
            if (std.fs.cwd().statFile(fname)) |stat| {
                if (stat.kind == std.fs.File.Kind.file) {
                } else { return; }
            } else |_| { return; }
        } else |_| { return; }
    }

    const wwnd = df.WatchIcon();
    wndpos += 2;
    if (wndpos == 20)
        wndpos = 2;
    const wnd1 = df.CreateWindow(df.EDITBOX,
                fname.ptr,
                (wndpos-1)*2, wndpos, 10, 40,
                null, wnd, df.OurEditorProc,
                df.SHADOW     |
                df.MINMAXBOX  |
                df.CONTROLBOX |
                df.VSCROLLBAR |
                df.HSCROLLBAR |
                df.MOVEABLE   |
                df.HASBORDER  |
                df.SIZEABLE   |
                df.MULTILINE
    );

    if (std.mem.eql(u8, fname, sUntitled) == false) {
        wnd1.*.extension = df.DFmalloc(fname.len+1);
        const ext:[*c]u8 = @ptrCast(wnd1.*.extension);
        // wnd.extension is used to store filename.
        // it is also be used to compared already opened files.
        _ = df.strcpy(ext, fname.ptr);

        LoadFile(wnd1, fname);
    }
    _ = df.SendMessage(wwnd, df.CLOSE_WINDOW, 0, 0);
    _ = df.SendMessage(wnd1, df.SETFOCUS, df.TRUE, 0);
}

// --- Load the notepad file into the editor text buffer ---
fn LoadFile(wnd: df.WINDOW, filename: []const u8) void {
    if (std.fs.cwd().readFileAlloc(allocator, filename, 1_048_576)) |content| {
        defer allocator.free(content);
        const buf:[*c]u8 = content.ptr;
        df.SendTextMessage(wnd, buf);
    } else |_| {
    }
}

const std = @import("std");

// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
