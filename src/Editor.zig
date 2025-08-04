const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

// ------- Window processing module for EDITBOX class ------
pub export fn EditorProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch(message) {
        df.KEYBOARD => {
            if (df.EditorKeyboardMsg(wnd, p1, p2) > 0)
                return df.TRUE;
        },
        df.SETTEXT => {
            const p1_addr:usize = @intCast(p1);
            return df.EditorSetTextMsg(wnd, @ptrFromInt(p1_addr));
        },
        else => {
        }
    }
    return root.BaseWndProc(df.EDITOR, wnd, message, p1, p2);
}
