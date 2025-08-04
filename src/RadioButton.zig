const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

pub export fn RadioButtonProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const control = df.GetControl(wnd);
    if (control) |ct| {
        switch (message) {
            df.SETFOCUS => {
                if (p1 == 0)
                    _ = df.SendMessage(null, df.HIDE_CURSOR, 0, 0);
            },
            df.MOVE => {
                const rtn = root.BaseWndProc(df.RADIOBUTTON,wnd,message,p1,p2);
                df.SetFocusCursor(wnd);
                return rtn;
            },
            df.PAINT => {
                var rb = "( )";
                if (ct.*.setting > 0)
                    rb = "(\x07)";
                _ = df.SendMessage(wnd, df.CLEARTEXT, 0, 0);
                _ = df.SendMessage(wnd, df.ADDTEXT, @intCast(@intFromPtr(rb.ptr)), 0);
                _ = df.SetFocusCursor(wnd);
            },
            df.KEYBOARD => {
//                if ((int)p1 != ' ')
//                    break;
            },
            df.LEFT_BUTTON => {
                if (df.GetParent(wnd).*.extension) |extension| {
                    const db:*df.DBOX = @alignCast(@ptrCast(extension));
                    df.SetRadioButton(db, ct);
                }
            },
            else => { 
            }
        }
    }
    return root.BaseWndProc(df.RADIOBUTTON, wnd, message, p1, p2);
}
