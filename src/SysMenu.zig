const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

pub export fn SystemMenuProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));
    switch (message) {
        df.CREATE_WINDOW => {
            wnd.*.holdmenu = df.ActiveMenuBar;
            df.ActiveMenuBar = &df.SystemMenu;
            df.SystemMenu.PullDown[0].Selection = 0;
        },
        df.LEFT_BUTTON => {
            const wnd1 = df.GetParent(wnd);
            const mx = p1 - win.GetLeft();
            const my = p2 - win.GetTop();
            if (df.HitControlBox(wnd1, mx, my))
                return df.TRUE;
        },
        df.LB_CHOOSE => {
            df.PostMessage(wnd, df.CLOSE_WINDOW, 0, 0);
        },
        df.DOUBLE_CLICK => {
            if (p2 == win.GetTop(df.GetParent(wnd))) {
                df.PostMessage(df.GetParent(wnd), message, p1, p2);
                _ = df.SendMessage(wnd, df.CLOSE_WINDOW, df.TRUE, 0);
            }
            return df.TRUE;
        },
        df.SHIFT_CHANGED => {
            return df.TRUE;
        },
        df.CLOSE_WINDOW => {
            df.ActiveMenuBar = wnd.*.holdmenu;
        },
        else => {
        }
    }
    return root.DefaultWndProc(wnd, message, p1, p2);
}

// ------- Build a system menu --------
pub export fn BuildSystemMenu(wnd: df.WINDOW) callconv(.c) void {
    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));
//    int lf, tp, ht, wd;
//    WINDOW SystemMenuWnd;
//
//    SystemMenu.PullDown[0].Selections[6].Accelerator = 
//        (GetClass(wnd) == APPLICATION) ? ALT_F4 : CTRL_F4;

    const lf = win.GetLeft()+1;
    const tp = win.GetTop(wnd)+1;
    const ht = df.MenuHeight(df.SystemMenu.PullDown[0].Selections);
    const wd = df.MenuWidth(df.SystemMenu.PullDown[0].Selections);

    if (lf+wd > df.SCREENWIDTH-1)
        lf = (df.SCREENWIDTH-1) - wd;
    if (tp+ht > df.SCREENHEIGHT-2)
        tp = (df.SCREENHEIGHT-2) - ht;

    const SystemMenuWnd = df.CreateWindow(df.POPDOWNMENU, null,
                lf,tp,ht,wd,null,wnd,SystemMenuProc, 0);

    _ = SystemMenuWnd;
//    if (wnd->condition == ISRESTORED)
//        DeactivateCommand(&SystemMenu, ID_SYSRESTORE);
//    else
//        ActivateCommand(&SystemMenu, ID_SYSRESTORE);
//
//    if (TestAttribute(wnd, MOVEABLE)
//            && wnd->condition != ISMAXIMIZED
//                )
//        ActivateCommand(&SystemMenu, ID_SYSMOVE);
//    else
//        DeactivateCommand(&SystemMenu, ID_SYSMOVE);
//
//    if (wnd->condition != ISRESTORED ||
//            TestAttribute(wnd, SIZEABLE) == FALSE)
//        DeactivateCommand(&SystemMenu, ID_SYSSIZE);
//    else
//        ActivateCommand(&SystemMenu, ID_SYSSIZE);
//
//    if (wnd->condition == ISMINIMIZED ||
//            TestAttribute(wnd, MINMAXBOX) == FALSE)
//        DeactivateCommand(&SystemMenu, ID_SYSMINIMIZE);
//    else
//        ActivateCommand(&SystemMenu, ID_SYSMINIMIZE);
//
//    if (wnd->condition != ISRESTORED ||
//            TestAttribute(wnd, MINMAXBOX) == FALSE)
//        DeactivateCommand(&SystemMenu, ID_SYSMAXIMIZE);
//    else
//        ActivateCommand(&SystemMenu, ID_SYSMAXIMIZE);
//
//    SendMessage(SystemMenuWnd, BUILD_SELECTIONS,
//                (PARAM) &SystemMenu.PullDown[0], 0);
//    SendMessage(SystemMenuWnd, SETFOCUS, TRUE, 0);
//    SendMessage(SystemMenuWnd, SHOW_WINDOW, 0, 0);
}
