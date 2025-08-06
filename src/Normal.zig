const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const helpbox = @import("HelpBox.zig");
const Classes = @import("Classes.zig");

var dummyWnd:?Window = null;

fn getDummy() Window {
    if(dummyWnd == null) {
        dummyWnd = Window.create(df.DUMMY, null, -1, -1, -1, -1, null, null, NormalProc, 0, root.global_allocator);
    }
    return dummyWnd.?;
}

// --------- CREATE_WINDOW Message ----------
fn CreateWindowMsg(wnd:df.WINDOW) void {
    df.AppendWindow(wnd);
    const rtn = df.SendMessage(null, df.MOUSE_INSTALLED, 0, 0);
    if (rtn == 0) {
        // FIXME: should use Window function
        wnd.*.attrib = wnd.*.attrib & ~(df.VSCROLLBAR | df.HSCROLLBAR);
//        df.ClearAttribute(wnd, df.VSCROLLBAR | df.HSCROLLBAR);
    }
    if (df.TestAttribute(wnd, df.SAVESELF)>0 and df.isVisible(wnd)>0) {
        df.GetVideoBuffer(wnd);
    }
}

// --------- SHOW_WINDOW Message ----------
fn ShowWindowMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) void {
    if (df.GetParent(wnd) == null or df.isVisible(df.GetParent(wnd))>0) {
        if (df.TestAttribute(wnd, df.SAVESELF)>0 and
                        (wnd.*.videosave == null)) {
            df.GetVideoBuffer(wnd);
        }
//        df.SetVisible(wnd);
//      FIXME: should use window function
        wnd.*.attrib = wnd.*.attrib | df.VISIBLE;

        _ = df.SendMessage(wnd, df.PAINT, 0, df.TRUE);
        _ = df.SendMessage(wnd, df.BORDER, 0, 0);
        // --- show the children of this window ---
        var cwnd = df.FirstWindow(wnd);
        while (cwnd) |cw| {
            if (cw.*.condition != df.ISCLOSING) {
                _ = df.SendMessage(cw, df.SHOW_WINDOW, p1, p2);
            }
            cwnd = df.NextWindow(cw);
        }
    }
}

// --------- HIDE_WINDOW Message ----------
fn HideWindowMsg(wnd:df.WINDOW) void {
    if (df.isVisible(wnd)>0) {
//        ClearVisible(wnd);
        wnd.*.attrib = wnd.*.attrib & ~df.VISIBLE; // FIXME: use window function
        // --- paint what this window covered ---
        if (df.TestAttribute(wnd, df.SAVESELF)>0) {
            df.PutVideoBuffer(wnd);
        } else {
            df.PaintOverLappers(wnd);
        }
        wnd.*.wasCleared = df.FALSE;
    }
}

// --------- COMMAND Message ----------
fn CommandMsg(wnd:df.WINDOW, p1:df.PARAM) void {
    const dummy = getDummy();
    switch (p1) {
        df.ID_SYSMOVE => {
            _ = df.SendMessage(wnd, df.CAPTURE_MOUSE, df.TRUE,
                @intCast(@intFromPtr(&dummy.win)));
            _ = df.SendMessage(wnd, df.CAPTURE_KEYBOARD, df.TRUE,
                @intCast(@intFromPtr(&dummy.win)));
            _ = df.SendMessage(wnd, df.MOUSE_CURSOR, df.GetLeft(wnd), df.GetTop(wnd));
            df.WindowMoving = df.TRUE;
            df.dragborder(wnd, df.GetLeft(wnd), df.GetTop(wnd));
        },
        df.ID_SYSSIZE => {
            _ = df.SendMessage(wnd, df.CAPTURE_MOUSE, df.TRUE,
                @intCast(@intFromPtr(&dummy.win)));
            _ = df.SendMessage(wnd, df.CAPTURE_KEYBOARD, df.TRUE,
                @intCast(@intFromPtr(&dummy.win)));
            _ = df.SendMessage(wnd, df.MOUSE_CURSOR, df.GetRight(wnd), df.GetBottom(wnd));
            df.WindowSizing = df.TRUE;
            df.dragborder(wnd, df.GetLeft(wnd), df.GetTop(wnd));
        },
        df.ID_SYSCLOSE => {
            _ = df.SendMessage(wnd, df.CLOSE_WINDOW, 0, 0);
            df.SkipApplicationControls();
        },
        df.ID_SYSRESTORE => {
            _ = df.SendMessage(wnd, df.RESTORE, 0, 0);
        },
        df.ID_SYSMINIMIZE => {
            _ = df.SendMessage(wnd, df.MINIMIZE, 0, 0);
        },
        df.ID_SYSMAXIMIZE => {
            _ = df.SendMessage(wnd, df.MAXIMIZE, 0, 0);
        },
        df.ID_HELP => {
            const klass = Classes.classdefs[@intCast(df.GetClass(wnd))][3];
            _ = helpbox.DisplayHelp(wnd, klass);
        },
        else => {
        }
    }
}

pub export fn NormalProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (message) {
        df.CREATE_WINDOW => {
            CreateWindowMsg(wnd);
        },
        df.SHOW_WINDOW => {
            ShowWindowMsg(wnd, p1, p2);
        },
        df.HIDE_WINDOW => {
            HideWindowMsg(wnd);
        },
        df.INSIDE_WINDOW => {
            return InsideWindow(wnd, @intCast(p1), @intCast(p2));
        },
        df.KEYBOARD => {
            if (df.NormalKeyboardMsg(wnd, p1, p2)>0)
                return df.TRUE;
            // ------- fall through -------
            if (df.GetParent(wnd) != null)
                df.PostMessage(df.GetParent(wnd), message, p1, p2);
        },
        df.ADDSTATUS, df.SHIFT_CHANGED => {
            if (df.GetParent(wnd) != null)
                df.PostMessage(df.GetParent(wnd), message, p1, p2);
        },
        df.PAINT => {
            if (df.isVisible(wnd)>0) {
                if (wnd.*.wasCleared > 0) {
                    df.PaintUnderLappers(wnd);
                } else {
                    wnd.*.wasCleared = df.TRUE;

                    var pp1:?*df.RECT = null;
                    if (p1>0) {
                        const p1_addr:usize = @intCast(p1);
                        pp1 = @ptrFromInt(p1_addr);
                    }

                    df.ClearWindow(wnd, pp1, ' ');
                }
            }
        },
        df.BORDER => {
            if (df.isVisible(wnd)>0) {
                var pp1:?*df.RECT = null;
                if (p1>0) {
                    const p1_addr:usize = @intCast(p1);
                    pp1 = @ptrFromInt(p1_addr);
                }

                if (df.TestAttribute(wnd, df.HASBORDER)>0) {
                    df.RepaintBorder(wnd, pp1);
                } else if (df.TestAttribute(wnd, df.HASTITLEBAR)>0) {
                    df.DisplayTitle(wnd, pp1);
                }
            }
        },
        df.COMMAND => {
            CommandMsg(wnd, p1);
        },
        else => {
            return df.cNormalProc(wnd, message, p1, p2);
        }
    }
    return df.TRUE;
}

// ----- test if screen coordinates are in a window ----
fn InsideWindow(wnd:df.WINDOW, x:c_int, y:c_int) c_int{
    var rc = df.WindowRect(wnd);
    if (df.TestAttribute(wnd, df.NOCLIP) == 0)    {
        var pwnd = df.GetParent(wnd);
        while (pwnd != null) {
            rc = df.subRectangle(rc, df.ClientRect(pwnd));
            pwnd = df.GetParent(pwnd);
        }
    }
    const rtn:c_int = df.cInsideRect(x, y, rc);
    return rtn;
}
