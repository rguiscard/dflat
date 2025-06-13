const df = mp.df;

var DFlatApplication = [_:0]u8{'m', 'e', 'm', 'o', 'p', 'a', 'd'};
var untitled = [_:0]u8{'U', 'n', 't', 'i', 't', 'l', 'e', 'd'};
const sUntitled = "Untitled";
var wndpos: c_int = 0;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    if (mp.msg.init_messages() == false)
        return;

    // Argv = argv;
    df.Argv = null;
    // if (!LoadConfig())
    //     cfg.ScreenLines = SCREENHEIGHT;

    const wnd = df.CreateWindow(df.APPLICATION, // Win
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

    var win = mp.Window.init(wnd, allocator);

    df.LoadHelpFile(&DFlatApplication);

    _ = win.sendMessage(df.SETFOCUS, df.TRUE, 0);

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
    const win:*mp.Window = @constCast(@fieldParentPtr("win", &wnd));

    switch(msg) {
        df.CREATE_WINDOW => {
            const rtn = mp.DefaultWndProc(wnd, msg, p1, p2);
            if (df.cfg.InsertMode == df.TRUE)
                df.SetCommandToggle(&df.MainMenu, df.ID_INSERT);
            if (df.cfg.WordWrap == df.TRUE)
                df.SetCommandToggle(&df.MainMenu, df.ID_WRAP);
            df.FixTabMenu();
            return rtn;
        },
        df.COMMAND => {
            switch(p1) {
                df.ID_NEW => {
                    NewFile(win);
                    return df.TRUE;
                },
                df.ID_OPEN => {
                    if (SelectFile(wnd)) {
                        return df.TRUE;
                    } else |_| {
                        return df.FALSE;
                    }
                },
                df.ID_SAVE => {
                    SaveFile(df.inFocus, df.FALSE);
                    return df.TRUE;
                },
                df.ID_SAVEAS => {
                    SaveFile(df.inFocus, df.TRUE);
                    return df.TRUE;
                },
                df.ID_DELETEFILE => {
                    DeleteFile(df.inFocus);
                    return df.TRUE;
                },
                df.ID_WRAP => {
                    df.cfg.WordWrap = df.GetCommandToggle(&df.MainMenu, df.ID_WRAP);
                    return df.TRUE;
                },
                df.ID_INSERT => {
                    df.cfg.InsertMode = df.GetCommandToggle(&df.MainMenu, df.ID_INSERT);
                    return df.TRUE;
                },
                df.ID_TAB2 => {
                    df.cfg.Tabs = 2;
                    df.FixTabMenu();
                    return df.TRUE;
                },
                df.ID_TAB4 => {
                    df.cfg.Tabs = 4;
                    df.FixTabMenu();
                    return df.TRUE;
                },
                df.ID_TAB6 => {
                    df.cfg.Tabs = 6;
                    df.FixTabMenu();
                    return df.TRUE;
                },
                df.ID_TAB8 => {
                    df.cfg.Tabs = 8;
                    df.FixTabMenu();
                    return df.TRUE;
                },
                df.ID_CALENDAR => {
                    df.Calendar(wnd);
                    return df.TRUE;
                },
                df.ID_BARCHART => {
                    df.BarChart(wnd);
                    return df.TRUE;
                },
                df.ID_EXIT => {
                    if (mp.msgbox.YesNoBox("Exit Memopad?") == false)
                        return df.FALSE;
                },
                df.ID_ABOUT => {
                    const message =
                        \\D-Flat implements the SAA/CUA
                        \\interface in a public domain
                        \\C language library originally
                        \\published in Dr. Dobb's Journal
                        \\------------------------
                        \\MemoPad is a multiple document
                        \\editor that demonstrates D-Flat
                    ;
                    _ = mp.msgbox.MessageBox("About D-Flat and the MemoPad", message);
                    return df.TRUE;
                },
                else => {
                    // return df.MemoPadProc(wnd, msg, p1, p2);
                }
            }
        },
        else => {
            //return df.MemoPadProc(wnd, msg, p1, p2);
        }
    }
    return mp.DefaultWndProc(wnd, msg, p1, p2);
}

// --- The New command. Open an empty editor window ---
fn NewFile(win: *mp.Window) void {
    OpenPadWindow(win.win, sUntitled);
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
    var wwin = mp.Window.init(wwnd, allocator);

    wndpos += 2;
    if (wndpos == 20)
        wndpos = 2;
    const wnd1 = df.CreateWindow(df.EDITBOX, // Win
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

    var win1 = mp.Window.init(wnd1, allocator);

    if (std.mem.eql(u8, fname, sUntitled) == false) {
        if (win1.setTitle(filename)) |_| {
        } else |_| {
        }

        LoadFile(win1, fname);
    }

    _ = wwin.sendMessage(df.CLOSE_WINDOW, 0, 0);
    _ = win1.sendMessage(df.SETFOCUS, df.TRUE, 0);
}

// --- Load the notepad file into the editor text buffer ---
fn LoadFile(win: mp.Window, filename: []const u8) void {
    var w = win;
    if (std.fs.cwd().readFileAlloc(allocator, filename, 1_048_576)) |content| {
        defer allocator.free(content);
        _ = w.sendTextMessage(df.SETTEXT, content, 0);
    } else |_| {
    }
}

// ---------- save a file to disk ------------ 
fn SaveFile(wnd: df.WINDOW, Saveas: c_int) void {
    var fspec = [_:0]u8{ '*'};
    var filename: [df.MAXPATH]u8 = undefined;
    if ((wnd.*.extension == null) or (Saveas == 1)) {
        if (df.SaveAsDialogBox(&fspec, null, &filename) == df.TRUE) {
            if (wnd.*.extension != df.NULL) {
                df.free(wnd.*.extension);
            }
            if (std.fs.cwd().realpathAlloc(allocator, ".")) |_| {
                wnd.*.extension = df.DFmalloc(df.strlen(&filename)+1);
                const ext:[*c]u8 = @ptrCast(wnd.*.extension);
                _ = df.strcpy(ext, &filename);
                df.AddTitle(wnd, df.NameComponent(&filename));
                _ = df.SendMessage(wnd, df.BORDER, 0, 0);
            } else |_| {
            }
        } else {
            return;
        }
    }
    if (wnd.*.extension != df.NULL) {
        const message:[]const u8 = "Saving the file";
        const mwnd = mp.msgbox.MomentaryMessage(message);

        const extension:[*c]u8 = @ptrCast(wnd.*.extension);
        const path:[:0]const u8 = std.mem.span(extension);
        const text:[*c]u8 = @ptrCast(wnd.*.text);
        const data:[:0]const u8 = std.mem.span(text);
        if (std.fs.cwd().writeFile(.{.sub_path = path, .data = data})) {
            wnd.*.TextChanged = df.FALSE;
        } else |_| {
        }

        _ = df.SendMessage(mwnd, df.CLOSE_WINDOW, 0, 0);
    }
}

// -------- delete a file ------------
fn DeleteFile(wnd: df.WINDOW) void {
    const extension:[*c]u8 = @ptrCast(wnd.*.extension);
    if (extension != null)    {
        const path:[:0]const u8 = std.mem.span(extension);
        if (std.mem.eql(u8, path, sUntitled) == false) {
            const fname:[*c]u8 = @ptrCast(df.NameComponent(extension));
            if (fname != null) {
                if (std.fmt.allocPrint(allocator, "Delete {s} ?", .{path})) |message| {
                    defer allocator.free(message);
                    if (mp.msgbox.YesNoBox(message) == true) {
                        if (std.fs.cwd().deleteFileZ(path)) |_| {
                        } else |_| {
                        }
                        _ = df.SendMessage(wnd, df.CLOSE_WINDOW, 0, 0);
                    }
                } else |_| {
                }
            }
        }
    }
}

const std = @import("std");

// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
