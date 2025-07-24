const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

pub export fn BoxProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const ct:?*df.CTLWINDOW = df.GetControl(wnd);
    if (ct) |ctl| {
        switch (message) {
            df.SETFOCUS, df.PAINT => {
                return df.FALSE;
            },
            df.LEFT_BUTTON, df.BUTTON_RELEASED => {
                return df.SendMessage(df.GetParent(wnd), message, p1, p2);
            },
            df.BORDER => {
                const rtn = root.BaseWndProc(df.BOX, wnd, message, p1, p2);
//                if (ct != NULL && ct->itext != NULL)
                if (ctl.*.itext) |txt| {
                    df.writeline(wnd, txt, 1, 0, df.FALSE);
                }
                return rtn;
            },
            else => {
            }
        }
    }
    return root.BaseWndProc(df.BOX, wnd, message, p1, p2);
}
