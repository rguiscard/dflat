const df = mp.df;
const command = mp.command;
const message = mp.msg.Message;

var DFlatApplication = [_:0]u8{'m', 'e', 'm', 'o', 'p', 'a', 'd'};
const sUntitled = "Untitled";
var wndpos: c_int = 0;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    if (mp.msg.init_messages() == false)
        return;

    // set global allocator for all callback in dflat.zig
    mp.setGlobalAllocator(allocator);

    // Argv = argv;
    df.Argv = null;
    // if (!LoadConfig())
    //     cfg.ScreenLines = SCREENHEIGHT;

    var win = mp.Window.create(df.APPLICATION, // Win
                        "D-Flat MemoPad",
                        0, 0, -1, -1,
                        &df.MainMenu,
                        null,
                        MemoPadProc,
                        df.MOVEABLE  |
                        df.SIZEABLE  |
                        df.HASBORDER |
                        df.MINMAXBOX |
                        df.HASSTATUSBAR,
                        allocator);

    df.LoadHelpFile(&DFlatApplication);

    _ = win.sendMessage(message.SETFOCUS, df.TRUE, 0);

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

    const mssg:message = @enumFromInt(msg);
    switch(mssg) {
        message.CREATE_WINDOW => {
            const rtn = mp.DefaultWndProc(wnd, msg, p1, p2);
            if (df.cfg.InsertMode == df.TRUE)
                df.SetCommandToggle(&df.MainMenu, df.ID_INSERT);
            if (df.cfg.WordWrap == df.TRUE)
                df.SetCommandToggle(&df.MainMenu, df.ID_WRAP);
            df.FixTabMenu();
            return rtn;
        },
        message.COMMAND => {
            const cmnd:command = @enumFromInt(p1);
            switch(cmnd) {
                command.ID_NEW => {
                    NewFile(win);
                    return df.TRUE;
                },
                command.ID_OPEN => {
                    if (SelectFile(win)) {
                        return df.TRUE;
                    } else |_| {
                        return df.FALSE;
                    }
                },
                command.ID_SAVE => {
                    SaveFile(df.inFocus, false);
                    return df.TRUE;
                },
                command.ID_SAVEAS => {
                    SaveFile(df.inFocus, true);
                    return df.TRUE;
                },
                command.ID_DELETEFILE => {
                    DeleteFile(df.inFocus);
                    return df.TRUE;
                },
                command.ID_WRAP => {
                    df.cfg.WordWrap = df.GetCommandToggle(&df.MainMenu, df.ID_WRAP);
                    return df.TRUE;
                },
                command.ID_INSERT => {
                    df.cfg.InsertMode = df.GetCommandToggle(&df.MainMenu, df.ID_INSERT);
                    return df.TRUE;
                },
                command.ID_TAB2 => {
                    df.cfg.Tabs = 2;
                    df.FixTabMenu();
                    return df.TRUE;
                },
                command.ID_TAB4 => {
                    df.cfg.Tabs = 4;
                    df.FixTabMenu();
                    return df.TRUE;
                },
                command.ID_TAB6 => {
                    df.cfg.Tabs = 6;
                    df.FixTabMenu();
                    return df.TRUE;
                },
                command.ID_TAB8 => {
                    df.cfg.Tabs = 8;
                    df.FixTabMenu();
                    return df.TRUE;
                },
                command.ID_CALENDAR => {
                    df.Calendar(wnd);
                    return df.TRUE;
                },
                command.ID_BARCHART => {
                    mp.barchart.BarChart(wnd);
                    return df.TRUE;
                },
                command.ID_EXIT => {
                    if (mp.msgbox.YesNoBox("Exit Memopad?") == false)
                        return df.FALSE;
                },
                command.ID_ABOUT => {
                    const m =
                        \\D-Flat implements the SAA/CUA
                        \\interface in a public domain
                        \\C language library originally
                        \\published in Dr. Dobb's Journal
                        \\------------------------
                        \\MemoPad is a multiple document
                        \\editor that demonstrates D-Flat
                    ;
                    _ = mp.msgbox.MessageBox("About D-Flat and the MemoPad", m);
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
fn SelectFile(win: *mp.Window) !void {
    const wnd = win.win;
    const fspec:[:0]const u8 = "*";
    var filename = std.mem.zeroes([1024]u8);

    if (mp.fileopen.OpenFileDialogBox(allocator, fspec, &filename)) {
        // --- see if the document is already in a window ---
        var wnd1:df.WINDOW = win.firstWindow();
        while (wnd1 != null) {
            const win1:*mp.Window = @constCast(@fieldParentPtr("win", &wnd1));
            if (wnd1.*.extension) |extension| {
                const ext:[*c]const u8 = @ptrCast(extension);
                if (df.strcasecmp(&filename, ext) == 0) {
                    _ = win1.sendMessage(mp.msg.Message.SETFOCUS, df.TRUE, 0);
                    _ = win1.sendMessage(mp.msg.Message.RESTORE, 0, 0);
                    return;
                }
            }
            wnd1 = df.NextWindow(wnd1);
        }

        var filename_it = std.mem.splitScalar(u8, &filename, 0);
        if (allocator.dupe(u8, filename_it.first())) |f| {
            // should free
            OpenPadWindow(wnd, f);
        } else |_| {
        }
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

    var wwin = mp.watch.WatchIcon();

    wndpos += 2;
    if (wndpos == 20)
        wndpos = 2;

    var win1 = mp.Window.create(df.EDITBOX, // Win
                fname,
                (wndpos-1)*2, wndpos, 10, 40,
                null, wnd, OurEditorProc,
                df.SHADOW     |
                df.MINMAXBOX  |
                df.CONTROLBOX |
                df.VSCROLLBAR |
                df.HSCROLLBAR |
                df.MOVEABLE   |
                df.HASBORDER  |
                df.SIZEABLE   |
                df.MULTILINE,
                allocator
    );

    if (std.mem.eql(u8, fname, sUntitled) == false) {
        if (win1.setTitle(filename)) |_| {
        } else |_| {
        }

        LoadFile(win1, fname);
    }

    _ = wwin.sendMessage(message.CLOSE_WINDOW, 0, 0);
    _ = win1.sendMessage(message.SETFOCUS, df.TRUE, 0);
}

// --- Load the notepad file into the editor text buffer ---
fn LoadFile(win: mp.Window, filename: []const u8) void {
    var w = win;
    if (std.fs.cwd().readFileAlloc(allocator, filename, 1_048_576)) |content| {
        defer allocator.free(content);
        _ = w.sendTextMessage(message.SETTEXT, content, 0);
    } else |_| {
    }
}

// ---------- save a file to disk ------------ 
fn SaveFile(wnd: df.WINDOW, Saveas: bool) void {
    const fspec:[:0]const u8 = "*";
    var filename: [df.MAXPATH]u8 = undefined;
    if ((wnd.*.extension == null) or (Saveas == true)) {
        if (mp.fileopen.SaveAsDialogBox(allocator, fspec, null, &filename)) {
            if (wnd.*.extension != df.NULL) {
                df.free(wnd.*.extension);
            }
            if (std.fs.cwd().realpathAlloc(allocator, ".")) |_| {
                // should free
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
        const m:[]const u8 = "Saving the file";
        var mwin = mp.msgbox.MomentaryMessage(m, allocator);

        const extension:[*c]u8 = @ptrCast(wnd.*.extension);
        const path:[:0]const u8 = std.mem.span(extension);
        const text:[*c]u8 = @ptrCast(wnd.*.text);
        const data:[]const u8 = std.mem.span(text);
        if (std.fs.cwd().writeFile(.{.sub_path = path, .data = data})) {
            wnd.*.TextChanged = df.FALSE;
        } else |_| {
        }

        _ = mwin.sendMessage(message.CLOSE_WINDOW, 0, 0);
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
                if (std.fmt.allocPrint(allocator, "Delete {s} ?", .{path})) |m| {
                    defer allocator.free(m);
                    if (mp.msgbox.YesNoBox(m) == true) {
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

// ----- window processing module for the editboxes -----
fn OurEditorProc(wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    var rtn:c_int = 0;
    const mssg:message = @enumFromInt(msg);
    switch (mssg) {
        message.SETFOCUS => {
            const param:isize = @intCast(p1);
            if (param > 0) {
                wnd.*.InsertMode = df.GetCommandToggle(&df.MainMenu, df.ID_INSERT);
                wnd.*.WordWrapMode = df.GetCommandToggle(&df.MainMenu, df.ID_WRAP);
            }
            rtn = mp.DefaultWndProc(wnd, msg, p1, p2);
            if (param == 0) {
                _ = df.SendMessage(df.GetParent(wnd), df.ADDSTATUS, 0, 0);
            } else {
                df.ShowPosition(wnd);
            }
            return rtn;
        },
        message.KEYBOARD_CURSOR => {
            rtn = mp.DefaultWndProc(wnd, msg, p1, p2);
            df.ShowPosition(wnd);
            return rtn;
        },
        message.COMMAND => {
            const cmnd:command = @enumFromInt(p1);
            switch(cmnd) {
                command.ID_HELP => {
                    const helpfile:[:0]const u8 = "MEMOPADDOC";
                    _ = df.DisplayHelp(wnd, @constCast(helpfile.ptr));
                    return df.TRUE;
                },
                command.ID_WRAP => {
                    _ = df.SendMessage(df.GetParent(wnd), df.COMMAND, df.ID_WRAP, 0);
                    wnd.*.WordWrapMode = df.cfg.WordWrap;
                },
                command.ID_INSERT => {
                    _ = df.SendMessage(df.GetParent(wnd), df.COMMAND, df.ID_INSERT, 0);
                    wnd.*.InsertMode = df.cfg.InsertMode;
                    _ = df.SendMessage(null, df.SHOW_CURSOR, wnd.*.InsertMode, 0);
                },
                else => {
                }
            }
        },
        message.CLOSE_WINDOW => {
            if (wnd.*.TextChanged > 0)    {
                _ = df.SendMessage(wnd, df.SETFOCUS, df.TRUE, 0);
                const tl:[*c]u8 = @ptrCast(wnd.*.title);
                const title:[:0]const u8 = std.mem.span(tl);
                if (std.fmt.allocPrint(allocator, "{s}\nText changed. Save it ?", .{title})) |m| {
                    defer allocator.free(m);
                    if (mp.msgbox.YesNoBox(m) == true) {
                        _ = df.SendMessage(df.GetParent(wnd), df.COMMAND, df.ID_SAVE, 0);
                    }
                } else |_| {
                }
            }
            wndpos = 0;
            if (wnd.*.extension != df.NULL)    {
                df.free(wnd.*.extension);
                wnd.*.extension = df.NULL;
            }
        },
        else => {
        }
    }
    return mp.DefaultWndProc(wnd, msg, p1, p2);
}


const std = @import("std");

// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const mp = @import("memopad");
