//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

// This make dflat public to all zig codes
pub const df = @import("ImportC.zig").df;
pub const Window = @import("Window.zig");
pub const msg = @import("Message.zig");

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

pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
