const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

pub export fn CheckBoxProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const ct:?*df.CTLWINDOW = df.GetControl(wnd);
    if (ct) |ctl| {
        switch (message)    {
            df.SETFOCUS => {
                if (p1 != 0)
                    _ = df.SendMessage(null, df.HIDE_CURSOR, 0, 0);
                // fall off ?
            },
            df.MOVE => {
                const rtn = root.BaseWndProc(df.CHECKBOX, wnd, message, p1, p2);
                df.SetFocusCursor(wnd);
                return rtn;
            },
            df.PAINT => {
                var cb = "[ ]";
                if (ctl.*.setting > 0)
                    cb = "[X]";
                _ = df.SendMessage(wnd, df.CLEARTEXT, 0, 0);
                _ = df.SendMessage(wnd, df.ADDTEXT, @intCast(@intFromPtr(cb.ptr)), 0);
                _ = df.SetFocusCursor(wnd);
            },
            df.KEYBOARD => {
//                if ((int)p1 != ' ')
//                    break;
            },
            df.LEFT_BUTTON => {
                if (ctl.*.setting == df.ON) {
                    ctl.*.setting = df.OFF;
                } else {
                    ctl.*.setting = df.ON;
                }
//                ct->setting ^= ON;
                _ = df.SendMessage(wnd, df.PAINT, 0, 0);
                return df.TRUE;
            },
            else => {
            }
        }
    }
    return root.BaseWndProc(df.CHECKBOX, wnd, message, p1, p2);
}

pub fn CheckBoxSetting(db:*df.DBOX, cmd:c_uint) c_uint {
    const ct:?*df.CTLWINDOW = df.FindCommand(db, @intCast(cmd), df.CHECKBOX);
    if (ct) |ctl| {
        if (ctl.*.wnd) |_| {
            return if (ctl.*.setting == df.ON) df.TRUE else df.FALSE;
        } else {
            return if (ctl.*.isetting == df.ON) df.TRUE else df.FALSE;
        }
    }
    return df.FALSE;
//    return ct ? (ct->wnd ? (ct->setting==ON) : (ct->isetting==ON)) : FALSE;
}
