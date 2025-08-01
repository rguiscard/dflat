const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

pub export fn StatusBarProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));
    switch (message) {
        df.CREATE_WINDOW => {
            _ = df.SendMessage(wnd, df.CAPTURE_CLOCK, 0, 0);
        },
        df.KEYBOARD => {
//                        if ((int)p1 == CTRL_F4)
//                                return TRUE;
//                        break;
        },
        df.PAINT => {
            if (df.isVisible(wnd) > 0) {
                const statusbar = root.global_allocator.alloc(u8, @intCast(win.WindowWidth()+1));
                if (statusbar) |sb| {
                    @memset(sb, ' ');
                    sb[sb.len-1] = '0';
                    const sub = "F1=Help";
                    @memcpy(sb[0..7], sub);

                    df.SetStandardColor(wnd);
                    df.PutWindowLine(wnd, @constCast(@ptrCast(sb)), 0, 0);
                    defer root.global_allocator.free(sb);
                    return df.TRUE;
                } else |_| {
                    // error
                }
//            statusbar = DFcalloc(1, WindowWidth(wnd)+1);
//                        memset(statusbar, ' ', WindowWidth(wnd));
//                        *(statusbar+WindowWidth(wnd)) = '\0';
//                        strncpy(statusbar+1, "F1=Help", 7);
//                        if (wnd->text)  {
//                                int len = min(strlen(wnd->text), WindowWidth(wnd)-17);
//                                if (len > 0)    {
//                                        int off=(WindowWidth(wnd)-len)/2;
//                                        strncpy(statusbar+off, wnd->text, len);
//                                }
//                        }
//                        if (wnd->TimePosted)
//                                *(statusbar+WindowWidth(wnd)-8) = '\0';
//                        else
//                                strncpy(statusbar+WindowWidth(wnd)-8, time_string, 9);
//            SetStandardColor(wnd);
//            PutWindowLine(wnd, statusbar, 0, 0);
//                        free(statusbar);
//                        return TRUE;
            }
        },
        df.BORDER => {
            return df.TRUE;
        },
        df.CLOCKTICK => {
            return df.StatusBarProc(wnd, message, p1, p2);
//                        SetStandardColor(wnd);
//                        PutWindowLine(wnd, (char *)p1, WindowWidth(wnd)-8, 0);
//                        wnd->TimePosted = TRUE;
//                        SendMessage(wnd->PrevClock, msg, p1, p2);
//                        return TRUE;
        },
        df.CLOSE_WINDOW => {
            _ = df.SendMessage(wnd, df.RELEASE_CLOCK, 0, 0);
        },
        else => {
        }
    }
    return root.BaseWndProc(df.STATUSBAR, wnd, message, p1, p2);
}
