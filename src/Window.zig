const std = @import("std");
const df = @import("ImportC.zig").df;
const message = @import("Message.zig").Message;

win: df.WINDOW,
title: ?[]const u8 = null,
allocator: std.mem.Allocator,

/// `@This()` can be used to refer to this struct type. In files with fields, it is quite common to
/// name the type here, so it can be easily referenced by other declarations in this file.
const TopLevelFields = @This();

pub fn init(wnd: df.WINDOW, allocator: std.mem.Allocator) TopLevelFields {
    return .{
        .win = wnd,
        .allocator = allocator,
    };
}

// ------- window methods -----------
pub fn WindowHeight(self: *TopLevelFields) isize {
    const wnd = self.win;
    return wnd.*.ht;
}

pub fn SetWindowHeight(self: *TopLevelFields, height: isize) void {
    const wnd = self.win;
    wnd.*.ht = @intCast(height);
}

pub fn WindowWidth(self: *TopLevelFields) isize {
    const wnd = self.win;
    return wnd.*.wd;
}

pub fn BorderAdj(self: *TopLevelFields) isize {
    var border:isize = 0;
    if (df.TestAttribute(self.win, df.HASBORDER) > 0) {
        border = 1;
    }
    return border;
}

pub fn BottomBorderAdj(self: *TopLevelFields) isize {
    var border = BorderAdj(self);
    if (df.TestAttribute(self.win, df.HASSTATUSBAR) > 0) {
        border = 1;
    }
    return border;
}

pub fn TopBorderAdj(self: *TopLevelFields) isize {
    var border:isize = 0;
    if ((df.TestAttribute(self.win, df.HASTITLEBAR) > 0) and (df.TestAttribute(self.win, df.HASMENUBAR) > 0)) {
        border = 2;
    } else {
        if (df.TestAttribute(self.win, df.HASTITLEBAR | df.HASMENUBAR | df.HASBORDER) > 0) {
            border = 1;
        }
    }
    return border;
}

pub fn ClientWidth(self: *TopLevelFields) isize {
    return (self.WindowWidth()-BorderAdj(self)*2);
}

pub fn ClientHeight(self: *TopLevelFields) isize {
    return (self.WindowHeight()-TopBorderAdj(self)-BottomBorderAdj(self));
}

pub fn WindowRect(self: *TopLevelFields) df.RECT {
    const wnd = self.win;
    return wnd.*.rc;
}

pub fn GetTop(self: *TopLevelFields) isize {
    const rect = self.WindowRect();
    return rect.tp;
}

pub fn GetBottom(self: *TopLevelFields) isize {
    const rect = self.WindowRect();
    return rect.bt;
}

pub fn SetBottom(self: *TopLevelFields, bottom: isize) void {
    self.win.*.rc.bt = @intCast(bottom);
}

pub fn GetLeft(self: *TopLevelFields) isize {
    const rect = self.WindowRect();
    return rect.lf;
}

pub fn GetRight(self: *TopLevelFields) isize {
    const rect = self.WindowRect();
    return rect.rt;
}

pub fn getParent(self: *TopLevelFields) df.WINDOW {
    const wnd = self.win;
    return wnd.*.parent;
}

pub fn firstWindow(self: *TopLevelFields) df.WINDOW {
    const wnd = self.win;
    return wnd.*.firstchild;
}

pub fn lastWindow(self: *TopLevelFields) df.WINDOW {
    const wnd = self.win;
    return wnd.*.lastchild;
}

pub fn nextWindow(self: *TopLevelFields) df.WINDOW {
    const wnd = self.win;
    return wnd.*.nextsibling;
}

pub fn prevWindow(self: *TopLevelFields) df.WINDOW {
    const wnd = self.win;
    return wnd.*.prevsibling;
}

// ------------- edit box prototypes -----------
pub fn CurrChar(self: *TopLevelFields) [*c]u8 {
    const w = self.win;
    const sel:usize = @intCast(w.*.CurrLine);
    const curr_col:usize = @intCast(w.*.CurrCol);
    return df.TextLine(w, sel)+curr_col;
}

pub fn WndCol(self: *TopLevelFields) isize {
    return self.win.*.CurrCol - self.win.*.wleft;
}

// --------- Accessories --------

// This set with win.title and wnd.ext as filename
pub fn setTitle(self: *TopLevelFields, filename: []const u8) !void {
    if (self.title != null) {
        self.allocator.free(filename);
    }
    self.title = try self.allocator.dupe(u8, filename);

    self.win.*.extension = df.DFmalloc(filename.len+1);
    const ext:[*c]u8 = @ptrCast(self.win.*.extension);
    // wnd.extension is used to store filename.
    // it is also be used to compared already opened files.
    _ = df.strcpy(ext, filename.ptr);
}

// -------- text box prototypes ----------
pub fn TextBlockMarked(self: *TopLevelFields) bool {
    const w = self.win;
    return (w.*.BlkBegLine > 0) or (w.*.BlkEndLine > 0) or (w.*.BlkBegCol > 0) or (w.*.BlkEndCol > 0);
}

pub fn ClearTextBlock(self: *TopLevelFields) void {
    const w = self.win;
    w.*.BlkBegLine = 0;
    w.*.BlkEndLine = 0;
    w.*.BlkBegCol = 0;
    w.*.BlkEndCol = 0;
}

// --------- message prototypes -----------

pub fn sendMessage(self: *TopLevelFields, msg: message, p1: df.PARAM, p2: df.PARAM) isize {
    const x = @intFromEnum(msg);
    const m:df.MESSAGE = @intCast(x);
    return df.SendMessage(self.win, m, p1, p2);
}

pub fn sendTextMessage(self: *TopLevelFields, msg: message, p1: []u8, p2: df.PARAM) isize {
    // message should only be df.SETTEXT ?
    const buf:[*c]u8 = p1.ptr;
    const x = @intFromEnum(msg);
    const m:df.MESSAGE = @intCast(x);
    return df.SendMessage(self.win, m, @intCast(@intFromPtr(buf)), p2);
}

pub fn deinit(self: *TopLevelFields) void {
    self.allocator.free(self.title);
}
