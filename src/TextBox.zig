const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

// ----------- TEXTBOX Message-processing Module -----------
pub export fn TextBoxProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    return df.cTextBoxProc(wnd, message, p1, p2);
}
