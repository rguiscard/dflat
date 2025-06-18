//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

// This make dflat public to all zig codes
pub const df = @import("ImportC.zig").df;
pub const Window = @import("Window.zig");
pub const msg = @import("Message.zig");
pub const msgbox = @import("MessageBox.zig");
pub const fileopen = @import("FileOpen.zig");
pub const command = @import("Commands.zig").Command;
pub const search = @import("Search.zig");

// ------- window methods -----------
pub fn BorderAdj(wnd: df.WINDOW) isize {
    var border:isize = 0;
    if (df.TestAttribute(wnd, df.HASBORDER) > 0) {
        border = 1;
    }
    return border;
}

pub fn BottomBorderAdj(wnd: df.WINDOW) isize {
    var border = BorderAdj(wnd);
    if (df.TestAttribute(wnd, df.HASSTATUSBAR) > 0) {
        border = 1;
    }
    return border;
}

pub fn TopBorderAdj(wnd: df.WINDOW) isize {
    var border:isize = 0;
    if ((df.TestAttribute(wnd, df.HASTITLEBAR) > 0) and (df.TestAttribute(wnd, df.HASMENUBAR) > 0)) {
        border = 2;
    } else {
        if (df.TestAttribute(wnd, df.HASTITLEBAR | df.HASMENUBAR | df.HASBORDER) > 0) {
            border = 1;
        }
    }
    return border;
}

pub fn ClientWidth(wnd: df.WINDOW) isize {
    return (df.WindowWidth(wnd)-BorderAdj(wnd)*2);
}

pub fn ClientHeight(wnd: df.WINDOW) isize {
    return (df.WindowHeight(wnd)-TopBorderAdj(wnd)-BottomBorderAdj(wnd));
}

pub fn BaseWndProc(klass: df.CLASS, wnd: df.WINDOW, mesg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) c_int {
    const base_class = df.classdefs[@intCast(klass)].base;
    if (df.classdefs[@intCast(base_class)].wndproc) |proc| {
        return proc(wnd, mesg, p1, p2);
    }

    return df.FALSE;
}

pub fn DefaultWndProc(wnd: df.WINDOW, mesg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) c_int {
    if (df.classdefs[@intCast(wnd.*.Class)].wndproc) |proc| {
        return proc(wnd, mesg, p1, p2);
    }
    return BaseWndProc(wnd.*.Class, wnd, mesg, p1, p2);
}

// ------------- edit box prototypes -----------
pub fn CurrChar(wnd: df.WINDOW) [*c]u8 {
    const w = wnd;
    const sel:usize = @intCast(w.*.CurrLine);
    const curr_col:usize = @intCast(w.*.CurrCol);
    return df.TextLine(w, sel)+curr_col;
}

pub fn WndCol(wnd: df.WINDOW) isize {
    return wnd.*.CurrCol - wnd.*.wleft;
}

// -------- text box prototypes ----------
pub fn TextBlockMarked(wnd: df.WINDOW) bool {
    return (wnd.*.BlkBegLine > 0) or (wnd.*.BlkEndLine > 0) or (wnd.*.BlkBegCol > 0) or (wnd.*.BlkEndCol > 0);
}

pub fn ClearTextBlock(wnd: df.WINDOW) void {
    const w = wnd;
    w.*.BlkBegLine = 0;
    w.*.BlkEndLine = 0;
    w.*.BlkBegCol = 0;
    w.*.BlkEndCol = 0;
}

// Export search.c function to c (used by editbox.c)
pub export fn SearchText(wnd: df.WINDOW) callconv(.c) void {
    search.SearchText(wnd);
}
pub export fn SearchNext(wnd: df.WINDOW) callconv(.c) void {
    search.SearchNext(wnd);
}
pub export fn ReplaceText(wnd: df.WINDOW) callconv(.c) void {
    search.ReplaceText(wnd);
}

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
