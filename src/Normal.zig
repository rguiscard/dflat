const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const helpbox = @import("HelpBox.zig");
const Classes = @import("Classes.zig");
const sysmenu = @import("SysMenu.zig");

var dummyWnd:?Window = null;
var px:c_int = -1;
var py:c_int = -1;
var diff:c_int = 0;

fn getDummy() Window {
    if(dummyWnd == null) {
        dummyWnd = Window.create(df.DUMMY, null, -1, -1, -1, -1, null, null, NormalProc, 0, root.global_allocator);
    }
    return dummyWnd.?;
}

fn getDwnd() df.WINDOW {
    return &df.dwnd;
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
//    const dummy = getDummy();
    const dwnd = getDwnd();
    switch (p1) {
        df.ID_SYSMOVE => {
            _ = df.SendMessage(wnd, df.CAPTURE_MOUSE, df.TRUE,
                @intCast(@intFromPtr(dwnd)));
            _ = df.SendMessage(wnd, df.CAPTURE_KEYBOARD, df.TRUE,
                @intCast(@intFromPtr(dwnd)));
            _ = df.SendMessage(wnd, df.MOUSE_CURSOR, df.GetLeft(wnd), df.GetTop(wnd));
            df.WindowMoving = df.TRUE;
//            df.dragborder(wnd, df.GetLeft(wnd), df.GetTop(wnd));
            dragborder(wnd, df.GetLeft(wnd), df.GetTop(wnd));
        },
        df.ID_SYSSIZE => {
            _ = df.SendMessage(wnd, df.CAPTURE_MOUSE, df.TRUE,
                @intCast(@intFromPtr(dwnd)));
            _ = df.SendMessage(wnd, df.CAPTURE_KEYBOARD, df.TRUE,
                @intCast(@intFromPtr(dwnd)));
            _ = df.SendMessage(wnd, df.MOUSE_CURSOR, df.GetRight(wnd), df.GetBottom(wnd));
            df.WindowSizing = df.TRUE;
            dragborder(wnd, df.GetLeft(wnd), df.GetTop(wnd));
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

// --------- DOUBLE_CLICK Message ----------
fn DoubleClickMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) void {
    const mx = p1 - df.GetLeft(wnd);
    const my = p2 - df.GetTop(wnd);
    if ((df.WindowSizing == 0) and (df.WindowMoving == 0)) {
        if (df.HitControlBox(wnd, mx, my)) {
            df.PostMessage(wnd, df.CLOSE_WINDOW, 0, 0);
            df.SkipApplicationControls();
        }
    }
}

// --------- KEYBOARD Message ----------
fn KeyboardMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) bool {
    _ = p2;
//    const dummy = getDummy();
    const dwnd = getDwnd();
    if ((df.WindowMoving>0) or (df.WindowSizing>0)) {
        // -- move or size a window with keyboard --
        const x = if (df.WindowMoving>0) df.GetLeft(dwnd) else df.GetRight(dwnd);
        var y = if (df.WindowMoving>0) df.GetTop(dwnd) else df.GetBottom(dwnd);
        switch (p1)    {
            df.ESC => {
                TerminateMoveSize(dwnd);
                return true;
            },
            df.UP => {
                if (y>0)
                    y -= 1;
            },
            df.DN => {
                if (y < df.SCREENHEIGHT-1)
                    y += 1;
            },
//            case FWD:
//                if (x < SCREENWIDTH-1)
//                    x++;
//                break;
//            case BS:
//                if (x)
//                    --x;
//                break;
            '\r' => {
                _ = df.SendMessage(wnd,df.BUTTON_RELEASED,x,y);
            },
            else => {
                return true;
            }
        }
        _ = df.SendMessage(wnd, df.MOUSE_CURSOR, x, y);
        _ = df.SendMessage(wnd, df.MOUSE_MOVED, x, y);
        return true;
    }
    switch (p1) {
//        case F1:
//            SendMessage(wnd, COMMAND, ID_HELP, 0);
//            return TRUE;
//        case ' ':
//            if ((int)p2 & ALTKEY)
//                if (TestAttribute(wnd, HASTITLEBAR))
//                    if (TestAttribute(wnd, CONTROLBOX))
//                        BuildSystemMenu(wnd);
//            return TRUE;
//        case CTRL_F4:
//            if (TestAttribute(wnd, CONTROLBOX)) {
//                SendMessage(wnd, CLOSE_WINDOW, 0, 0);
//                                SkipApplicationControls();
//                    return TRUE;
//                        }
//                        break;
        else => {
        }
    }
    return false;
}

// --------- MOVE Message ----------
fn MoveMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) void {
    const wasVisible = (df.isVisible(wnd) > 0);
    const xdif = p1 - wnd.*.rc.lf;
    const ydif = p2 - wnd.*.rc.tp;

    if ((xdif == 0) and (ydif == 0)) {
        return;
    }
    wnd.*.wasCleared = df.FALSE;
    if (wasVisible) {
        _ = df.SendMessage(wnd, df.HIDE_WINDOW, 0, 0);
    }
    wnd.*.rc.lf = @intCast(p1);
    wnd.*.rc.tp = @intCast(p2);
    wnd.*.rc.rt = df.GetLeft(wnd)+df.WindowWidth(wnd)-1;
    wnd.*.rc.bt = df.GetTop(wnd)+df.WindowHeight(wnd)-1;
    if (wnd.*.condition == df.ISRESTORED) {
        wnd.*.RestoredRC = wnd.*.rc;
    }

    var cwnd = df.FirstWindow(wnd);
    while (cwnd) |cw| {
        _ = df.SendMessage(cw, df.MOVE, cwnd.*.rc.lf+xdif, cwnd.*.rc.tp+ydif);
        cwnd = df.NextWindow(cw);
    }
    if (wasVisible)
        _ = df.SendMessage(wnd, df.SHOW_WINDOW, 0, 0);
}

// --------- LEFT_BUTTON Message ---------- 
fn LeftButtonMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) void {
//    const dummy = getDummy();
    const dwnd = getDwnd();
    const mx = p1 - df.GetLeft(wnd);
    const my = p2 - df.GetTop(wnd);
    if ((df.WindowSizing>0) or (df.WindowMoving>0))
        return;
    if (df.HitControlBox(wnd, mx, my)) {
//        df.BuildSystemMenu(wnd);
        sysmenu.BuildSystemMenu(wnd);
        return;
    }
    if ((my == 0) and (mx > -1) and (mx < df.WindowWidth(wnd))) {
        // ---------- hit the top border --------
//        if (TestAttribute(wnd, MINMAXBOX) &&
//                TestAttribute(wnd, HASTITLEBAR))  {
//            if (mx == WindowWidth(wnd)-2)    {
//                if (wnd->condition != ISRESTORED)
//                    /* --- hit the restore box --- */
//                    SendMessage(wnd, RESTORE, 0, 0);
//#ifdef INCLUDE_MAXIMIZE
//                else
//                    /* --- hit the maximize box --- */
//                    SendMessage(wnd, MAXIMIZE, 0, 0);
//#endif
//                return;
//            }
//#ifdef INCLUDE_MINIMIZE
//            if (mx == WindowWidth(wnd)-3)    {
//                /* --- hit the minimize box --- */
//                if (wnd->condition != ISMINIMIZED)
//                    SendMessage(wnd, MINIMIZE, 0, 0);
//                return;
//            }
//#endif
//        }
//#ifdef INCLUDE_MAXIMIZE
//        if (wnd->condition == ISMAXIMIZED)
//            return;
//#endif
        if (df.TestAttribute(wnd, df.MOVEABLE)>0)    {
            df.WindowMoving = df.TRUE;
            px = @intCast(mx);
            py = @intCast(my);
            diff = @intCast(mx);
            _ = df.SendMessage(wnd, df.CAPTURE_MOUSE, df.TRUE, @intCast(@intFromPtr(&dwnd)));
            dragborder(wnd, df.GetLeft(wnd), df.GetTop(wnd));
        }
        return;
    }
    if ((mx == df.WindowWidth(wnd)-1) and
            (my == df.WindowHeight(wnd)-1)) {
        // ------- hit the resize corner ------- 
        if (wnd.*.condition == df.ISMINIMIZED)
            return;
        if (df.TestAttribute(wnd, df.SIZEABLE) == 0)
            return;
//#ifdef INCLUDE_MAXIMIZE
//        if (wnd->condition == ISMAXIMIZED)    {
//            if (GetParent(wnd) == NULL)
//                return;
//            if (TestAttribute(GetParent(wnd),HASBORDER))
//                return;
//            /* ----- resizing a maximized window over a
//                    borderless parent ----- */
//            wnd = GetParent(wnd);
//                if (!TestAttribute(wnd, SIZEABLE))
//                return;
//        }
//#endif
        df.WindowSizing = df.TRUE;
        _ = df.SendMessage(wnd, df.CAPTURE_MOUSE, df.TRUE, @intCast(@intFromPtr(&dwnd)));
        dragborder(wnd, df.GetLeft(wnd), df.GetTop(wnd));
    }
}

// --------- MOUSE_MOVED Message ---------- 
fn MouseMovedMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) bool {
    if (df.WindowMoving>0) {
        var leftmost:c_int = 0;
        var topmost:c_int = 0;
        var bottommost:c_int = df.SCREENHEIGHT-2;
        var rightmost:c_int = df.SCREENWIDTH-2;
        var x:c_int = @intCast(p1 - diff);
        var y:c_int = @intCast(p2);
        if ((df.GetParent(wnd) != null) and 
                (df.TestAttribute(wnd, df.NOCLIP) == 0)) {
            const wnd1 = df.GetParent(wnd);
            // FIXME: it only works with Window
            const win1:*Window = @constCast(@fieldParentPtr("win", &wnd1));
            topmost    = @intCast(win1.GetClientTop());
            leftmost   = @intCast(win1.GetClientLeft());
            bottommost = @intCast(win1.GetClientBottom());
            rightmost  = @intCast(win1.GetClientRight());
        }
        if ((x < leftmost) or (x > rightmost) or 
                (y < topmost) or (y > bottommost))    {
            x = @max(x, leftmost);
            x = @min(x, rightmost);
            y = @max(y, topmost);
            y = @min(y, bottommost);
            _ = df.SendMessage(null,df.MOUSE_CURSOR,x+diff,y);
        }
        if ((x != px) or  (y != py))    {
            px = x;
            py = y;
            dragborder(wnd, x, y);
        }
        return true;
    }
    if (df.WindowSizing>0) {
//        df.sizeborder(wnd, @intCast(p1), @intCast(p2));
        sizeborder(wnd, @intCast(p1), @intCast(p2));
        return true;
    }
    return false;
}

// --------- SIZE Message ----------
fn SizeMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) void {
    const wasVisible = df.isVisible(wnd);
    const xdif:c_int = @intCast(p1 - wnd.*.rc.rt);
    const ydif:c_int = @intCast(p2 - wnd.*.rc.bt);

    if ((xdif == 0) and (ydif == 0)) {
        return;
    }
    wnd.*.wasCleared = df.FALSE;
    if (wasVisible > 0) {
        _ = df.SendMessage(wnd, df.HIDE_WINDOW, 0, 0);
    }
    wnd.*.rc.rt = @intCast(p1);
    wnd.*.rc.bt = @intCast(p2);
    wnd.*.ht = df.GetBottom(wnd)-df.GetTop(wnd)+1;
    wnd.*.wd = df.GetRight(wnd)-df.GetLeft(wnd)+1;

    if (wnd.*.condition == df.ISRESTORED)
        wnd.*.RestoredRC = df.WindowRect(wnd);

//#ifdef INCLUDE_MAXIMIZE
//    RECT rc;
//    rc = ClientRect(wnd);
//
//    WINDOW cwnd;
//        cwnd = FirstWindow(wnd);
//        while (cwnd != NULL)    {
//        if (cwnd->condition == ISMAXIMIZED)
//            SendMessage(cwnd, SIZE, RectRight(rc), RectBottom(rc));
//                cwnd = NextWindow(cwnd);
//    }
//#endif

    if (wasVisible > 0)
        _ = df.SendMessage(wnd, df.SHOW_WINDOW, 0, 0);
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
            if (KeyboardMsg(wnd, p1, p2))
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
        df.SETFOCUS => {
            df.SetFocusMsg(wnd, p1);
        },
        df.DOUBLE_CLICK => {
            DoubleClickMsg(wnd, p1, p2);
        },
        df.LEFT_BUTTON => {
            LeftButtonMsg(wnd, p1, p2);
        },
        df.MOUSE_MOVED => {
            if (MouseMovedMsg(wnd, p1, p2)) {
                return df.TRUE;
            }
        },
        df.BUTTON_RELEASED => {
            if ((df.WindowMoving>0) or (df.WindowSizing>0)) {
//                const dummy = getDummy();
                const dwnd = getDwnd();
                if (df.WindowMoving > 0) {
                    df.PostMessage(wnd,df.MOVE,dwnd.*.rc.lf,dwnd.*.rc.tp);
                } else {
                    df.PostMessage(wnd,df.SIZE,dwnd.*.rc.rt,dwnd.*.rc.bt);
                }
                TerminateMoveSize(dwnd);
            }
        },
        df.MOVE => {
            MoveMsg(wnd, p1, p2);
        },
        df.SIZE => {
            SizeMsg(wnd, p1, p2);
        },
//        case CLOSE_WINDOW:
//            CloseWindowMsg(wnd);
//            break;
//        case MAXIMIZE:
//            if (wnd->condition != ISMAXIMIZED)
//                MaximizeMsg(wnd);
//            break;
//        case MINIMIZE:
//            if (wnd->condition != ISMINIMIZED)
//                MinimizeMsg(wnd);
//            break;
//        case RESTORE:
//            if (wnd->condition != ISRESTORED)    {
//                if (wnd->oldcondition == ISMAXIMIZED)
//                    SendMessage(wnd, MAXIMIZE, 0, 0);
//                else
//                    RestoreMsg(wnd);
//            }
//            break;
        df.DISPLAY_HELP => {
            const p1_addr:usize = @intCast(p1);
            const pp1:[*c]u8 = @ptrFromInt(p1_addr);
            return helpbox.DisplayHelp(wnd, std.mem.span(pp1));
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

// ----- terminate the move or size operation -----
fn TerminateMoveSize(dwnd:df.WINDOW) void {
    px = -1;
    py = -1;
    diff = 0;
    _ = df.SendMessage(dwnd, df.RELEASE_MOUSE, df.TRUE, 0);
    _ = df.SendMessage(dwnd, df.RELEASE_KEYBOARD, df.TRUE, 0);
    df.RestoreBorder(dwnd.*.rc);
    df.WindowMoving = df.FALSE;
    df.WindowSizing = df.FALSE;
}

// ---- build a dummy window border for moving or sizing ---
fn dragborder(wnd:df.WINDOW, x:c_int, y:c_int) void {
//    const dummy = getDummy();
    const dwnd = getDwnd();

    df.RestoreBorder(dwnd.*.rc);
    // ------- build the dummy window --------
    dwnd.*.rc.lf = x;
    dwnd.*.rc.tp = y;
    dwnd.*.rc.rt = dwnd.*.rc.lf+df.WindowWidth(wnd)-1;
    dwnd.*.rc.bt = dwnd.*.rc.tp+df.WindowHeight(wnd)-1;
    dwnd.*.ht = df.WindowHeight(wnd);
    dwnd.*.wd = df.WindowWidth(wnd);
    dwnd.*.parent = df.GetParent(wnd);
    dwnd.*.attrib = df.VISIBLE | df.HASBORDER | df.NOCLIP;
    df.InitWindowColors(dwnd);
    df.SaveBorder(dwnd.*.rc);
    df.RepaintBorder(dwnd, null);
}

// FIXME: not working
// ---- write the dummy window border for sizing ----
fn sizeborder(wnd:df.WINDOW, rt:c_int, bt:c_int) void {
    // FIXME: it assumes Window is used.
//    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));

//    const dummy = getDummy();
    const dwnd = getDwnd();

    const leftmost:c_int = @intCast(df.GetLeft(wnd)+10);
    const topmost:c_int = @intCast(df.GetTop(wnd)+3);
    var bottommost:c_int = @intCast(df.SCREENHEIGHT-1);
    var rightmost:c_int = @intCast(df.SCREENWIDTH-1);
    if (df.GetParent(wnd) > 0) {
        const pwnd = df.GetParent(wnd);
        // FIXME: it assumes Window is used.
        const pwin:*Window = @constCast(@fieldParentPtr("win", &pwnd));

        bottommost = @intCast(@min(bottommost, pwin.GetClientBottom()));
        rightmost  = @intCast(@min(rightmost, pwin.GetClientRight()));
    }
    var new_rt:c_int = @min(rt, rightmost);
    var new_bt:c_int = @min(bt, bottommost);
    new_rt = @max(new_rt, leftmost);
    new_bt = @max(new_bt, topmost);
    _ = df.SendMessage(null, df.MOUSE_CURSOR, new_rt, new_bt);

    if ((rt != px) or (bt != py))
        df.RestoreBorder(dwnd.*.rc);

    // ------- change the dummy window --------
    dwnd.*.ht = bt-dwnd.*.rc.tp+1;
    dwnd.*.wd = rt-dwnd.*.rc.lf+1;
    dwnd.*.rc.rt = rt;
    dwnd.*.rc.bt = bt;
    if ((rt != px) or (bt != py)) {
        px = rt;
        py = bt;
        df.SaveBorder(dwnd.*.rc);
        df.RepaintBorder(dwnd, null);
    }
}
