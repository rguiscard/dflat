const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");

fn PaintMsg(wnd: df.WINDOW, ct: *df.CTLWINDOW, rc: ?*df.RECT) void {
    if (df.isVisible(wnd) > 0)    {
        if (((wnd.*.attrib & df.SHADOW) > 0) and (df.cfg.mono == 0)) { // use TestAttribute later
            // -------- draw the button's shadow -------
            df.background = df.WndBackground(df.GetParent(wnd));
            df.foreground = df.BLACK;
            for(1..@intCast(df.WindowWidth(wnd)+1)) |x| {
                df.wputch(wnd, 223, @intCast(x), 1);
            }
            df.wputch(wnd, 220, df.WindowWidth(wnd), 0);
        }
        if (ct.*.itext != null) {
            if(root.global_allocator.alloc(u8, df.strlen(ct.*.itext)+10)) |txt| {
                defer root.global_allocator.free(txt);
                @memset(txt, 0);
                var start:usize = 0;
                if (ct.*.setting == df.OFF) {
                  txt[0] = df.CHANGECOLOR;
                  txt[1] = wnd.*.WindowColors[df.HILITE_COLOR][df.FG] | 0x80;
                  txt[2] = wnd.*.WindowColors[df.STD_COLOR][df.BG] | 0x80;
                  start = 3;
                }
                _ = df.CopyCommand(&txt[start],ct.*.itext,if (ct.*.setting == df.OFF) 1 else 0, df.WndBackground(wnd));
                _ = df.SendMessage(wnd, df.CLEARTEXT, 0, 0);
                _ = df.SendMessage(wnd, df.ADDTEXT, @intCast(@intFromPtr(txt.ptr)), 0);
            } else |_| {
            }
        }
        // --------- write the button's text -------
        df.WriteTextLine(wnd, rc, 0, if (wnd == df.inFocus) 1 else 0 );
    }
}

fn LeftButtonMsg(wnd: df.WINDOW, msg: df.MESSAGE, ct: *df.CTLWINDOW) void {
    if (df.cfg.mono == 0) {
        // --------- draw a pushed button --------
        df.background = df.WndBackground(df.GetParent(wnd));
        df.foreground = df.WndBackground(wnd);
        df.wputch(wnd, ' ', 0, 0);
        for (0..@intCast(df.WindowWidth(wnd))) |x| {
            df.wputch(wnd, 220, @intCast(x+1), 0);
            df.wputch(wnd, 223, @intCast(x+1), 1);
        }
    }
    if (msg == df.LEFT_BUTTON) {
        _ = df.SendMessage(null, df.WAITMOUSE, 0, 0);
    } else {
        _ = df.SendMessage(null, df.WAITKEYBOARD, 0, 0);
    }
    _ = df.SendMessage(wnd, df.PAINT, 0, 0);
    if (ct.*.setting == df.ON) {
        df.PostMessage(df.GetParent(wnd), df.COMMAND, ct.*.command, 0);
    } else {
        df.beep();
    }
}

pub export fn ButtonProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const ct = df.GetControl(wnd);
    if (ct != null)    {
        switch (message)    {
            df.SETFOCUS => {
                _ = root.BaseWndProc(df.BUTTON, wnd, message, p1, p2);
                PaintMsg(wnd, ct, null);
                return df.TRUE;
            },
            df.PAINT => {
                const ptr:usize = @intCast(p1);
                PaintMsg(wnd, ct, @ptrFromInt(ptr));
                return df.TRUE;
            },
            df.KEYBOARD => {
//                if (p1 != '\r')
//                    break;
//                LeftButtonMsg(wnd, message, ct);
                return df.TRUE;
            },
            df.LEFT_BUTTON => {
                LeftButtonMsg(wnd, message, ct);
                return df.TRUE;
            },
            df.HORIZSCROLL => {
                return df.TRUE;
            },
            else => {
            }
        }
    }
    return root.BaseWndProc(df.BUTTON, wnd, message, p1, p2);
}
