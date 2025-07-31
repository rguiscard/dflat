const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

// ComboBox is not used in memopad. Port it later

pub export fn ComboProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    return root.BaseWndProc(df.COMBOBOX, wnd, message, p1, p2);
}
