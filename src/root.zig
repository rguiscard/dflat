//! By convention, root.zig is the root source file when making a library. If
//! you are making an executable, the convention is to delete this file and
//! start with main.zig instead.
const std = @import("std");
const testing = std.testing;

// This make dflat public to all zig codes
pub const df = @import("ImportC.zig").df;
pub const Window = @import("Window.zig");
pub const DBox = @import("DBox.zig");
pub const msg = @import("Message.zig");
pub const msgbox = @import("MessageBox.zig");
pub const fileopen = @import("FileOpen.zig");
pub const command = @import("Commands.zig").Command;
pub const search = @import("Search.zig");
pub const Classes = @import("Classes.zig");
pub const app = @import("Application.zig");

pub var global_allocator:std.mem.Allocator = undefined;

pub fn setGlobalAllocator(allocator: std.mem.Allocator) void {
    global_allocator = allocator;
}

pub fn BaseWndProc(klass: df.CLASS, wnd: df.WINDOW, mesg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) c_int {
    const base_class = Classes.classdefs[@intCast(klass)][0]; // base
    const index:c_int = @intFromEnum(base_class);
    if (Classes.classdefs[@intCast(index)][1]) |proc| { // wndproc
        return proc(wnd, mesg, p1, p2);
    }

    return df.FALSE;
}

pub fn DefaultWndProc(wnd: df.WINDOW, mesg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) c_int {
    const klass = wnd.*.Class;
    if (Classes.classdefs[@intCast(klass)][1]) |proc| { // wndproc
        return proc(wnd, mesg, p1, p2);
    }
    return BaseWndProc(klass, wnd, mesg, p1, p2);
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
