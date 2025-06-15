const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

var _allocator: std.mem.Allocator = undefined;
var _fileSpec:?[]const u8 = null;
var _srchSpec:?[]const u8 = null;
var _fileName:?[]const u8 = null;

fn set_fileSpec(text: []const u8) void {
    if (_fileSpec) |f| {
      _allocator.free(f);
    }
    if (_allocator.dupe(u8, text)) |t| {
        _fileSpec = t;
    } else |_| {
    }
}

fn set_srchSpec(text: []const u8) void {
    if (_srchSpec) |s| {
      _allocator.free(s);
    }
    if (_allocator.dupe(u8, text)) |t| {
        _srchSpec = t;
    } else |_| {
    }
}

fn set_fileName(text: []const u8) void {
    if (_fileName) |n| {
      _allocator.free(n);
    }
    if (_allocator.dupe(u8, text)) |t| {
        _fileName = t;
    } else |_| {
    }
}

// Dialog Box to select a file to open
pub fn OpenFileDialogBox(allocator: std.mem.Allocator, Fspec:[]const u8, Fname:[*c]u8) bool {
    var fBox = df.c_FileOpen();
    return DlgFileOpen(allocator, Fspec, Fspec, Fname, &fBox);
}

// Dialog Box to select a file to save as
pub fn SaveAsDialogBox(allocator: std.mem.Allocator, Fspec:[]const u8, Sspec:?[]const u8, Fname:[*c]u8) bool {
    var sBox = df.c_SaveAs();
    return DlgFileOpen(allocator, Fspec, Sspec orelse Fspec, Fname, &sBox);
}

// --------- generic file open ----------
pub fn DlgFileOpen(allocator: std.mem.Allocator, Fspec: []const u8, Sspec: []const u8, Fname:[*c]u8, db: *df.DBOX) bool {
    _allocator = allocator;

    // Keep a copy of Fspec, Sspec; Fname is returned value
    set_fileSpec(Fspec);
    set_srchSpec(Sspec);

    const result = df.DialogBox(null, db, df.TRUE, DlgFnOpen);
    const rtn = (result > 0);
    if (rtn) {
        if (_fileName) |n| {
            _ = df.strcpy(Fname, n.ptr);
        }
    }
    return rtn;
}

fn DlgFnOpen(wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (msg)    {
        df.CREATE_WINDOW => {
            const rtn = root.DefaultWndProc(wnd, msg, p1, p2);
            var db:*df.DBOX = undefined;
            if (wnd.*.extension) |extension| {
                db = @ptrCast(@alignCast(extension));
            }
            const cwnd = df.ControlWindow(db, df.ID_FILENAME);
            _ = df.SendMessage(cwnd, df.SETTEXTLENGTH, 64, 0);
            return rtn;
        },
        df.INITIATE_DIALOG => {
            InitDlgBox(wnd);
        },
        df.COMMAND => {
            const command:isize = @intCast(p1);
            switch(command) {
                df.ID_OK => {
                    const subcommand:isize = @intCast(p2);
                    if (subcommand == 0) {
                        var fName = std.mem.zeroes([1024]u8);
                        df.GetItemText(wnd, df.ID_FILENAME, &fName, df.MAXPATH);
                        set_fileName(&fName);
                        if (df.CheckAndChangeDir(&fName) > 0) {
                            std.mem.copyForwards(u8, &fName, "*");
                            set_fileName(&fName);
                        }
                        if (IncompleteFilename(&fName)) {
                            // --- no file name yet ---
                            var db:*df.DBOX = undefined;
                            if (wnd.*.extension) |extension| {
                                db = @ptrCast(@alignCast(extension));
                            }
                            const cwnd = df.ControlWindow(db, df.ID_FILENAME);
                            set_fileSpec(&fName);
                            set_srchSpec(&fName);
                            InitDlgBox(wnd);
                            _ = df.SendMessage(cwnd, df.SETFOCUS, df.TRUE, 0);
                            return df.TRUE;
                        }
                    }
                },
                df.ID_FILES => {
                    const subcommand:isize = @intCast(p2);
                    switch (subcommand) {
                        df.ENTERFOCUS, df.LB_SELECTION => {
                            // selected a different filename
                            var fName = std.mem.zeroes([1024]u8);
                            df.GetDlgListText(wnd, &fName, df.ID_FILES);
                            df.PutItemText(wnd, df.ID_FILENAME, &fName);
                            set_fileName(&fName);
                        },
                        df.LB_CHOOSE => {
                            // chose a file name
                            var fName = std.mem.zeroes([1024]u8);
                            df.GetDlgListText(wnd, &fName, df.ID_FILES);
                            _ = df.SendMessage(wnd, df.COMMAND, df.ID_OK, 0);
                            set_fileName(&fName);
                        },
                        else => {
                        }
                    }
                    return df.TRUE;
                },
                df.ID_DIRECTORY => {
                    const subcommand:isize = @intCast(p2);
                    switch (subcommand) {
                        df.ENTERFOCUS => {
                            if (_fileSpec) |f| {
                                df.PutItemText(wnd, df.ID_FILENAME, @constCast(f.ptr));
                            }
                        },
                        df.LB_CHOOSE => {
                            var dd = std.mem.zeroes([1024]u8);
                            df.GetDlgListText(wnd, &dd, df.ID_DIRECTORY);
                            _ = df.chdir(&dd);
                            InitDlgBox(wnd);
                            _ = df.SendMessage(wnd, df.COMMAND, df.ID_OK, 0);
                        },
                        else => {
                        }
                    }
                    return df.TRUE;
                 },
                else => {
                }
            }
        },
        else => {
        }
    }
    return root.DefaultWndProc(wnd, msg, p1, p2);
}


//  Initialize the dialog box
fn InitDlgBox(wnd:df.WINDOW) void {
    var sspec:[*c]u8 = null;
    if (_fileSpec) |f| {
        df.PutItemText(wnd, df.ID_FILENAME, @constCast(f.ptr));
    }
    if (_srchSpec) |s| {
        sspec = @constCast(s.ptr);
    }

    const rtn = df.BuildFileList(wnd, sspec);
    if (rtn == df.TRUE) {
        df.BuildDirectoryList(wnd);
    }
    df.BuildPathDisplay(wnd);
}

fn IncompleteFilename(s: [*c]u8) bool {
    const lc = df.strlen(s)-1;
    if (s == null)
        return true;
    if (lc == 0)
        return true;
    if ((df.strchr(s, '?') != null) or (df.strchr(s, '*') != null) or (s[0] == 0))
        return true;
    return false;
}
