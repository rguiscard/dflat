const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
//const DialogBox = @import("DialogBox.zig");
//const msg = @import("Message.zig").Message;

var ScreenHeight:c_int = 0;

pub fn ApplicationProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));

    switch (message) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win);
        },
        else => {
        }
    }
//    return root.BaseWndProc(df.APPLICATION, wnd, message, p1, p2);
    return df.ApplicationProc(wnd, message, p1, p2);
}

// --------------- CREATE_WINDOW Message --------------
fn CreateWindowMsg(win: *Window) c_int {
    const wnd = win.win;
    df.ApplicationWindow = wnd;
    ScreenHeight = df.SCREENHEIGHT;

    // INCLUDE_WINDOWOPTIONS
    if (df.cfg.Border > 0) {
        df.SetCheckBox(&df.Display, df.ID_BORDER);
    }
    if (df.cfg.Title > 0) {
        df.SetCheckBox(&df.Display, df.ID_TITLE);
    }
    if (df.cfg.StatusBar > 0) {
        df.SetCheckBox(&df.Display, df.ID_STATUSBAR);
    }
    if (df.cfg.Texture > 0) {
        df.SetCheckBox(&df.Display, df.ID_TEXTURE);
    }
    if (df.cfg.mono == 1) {
        df.PushRadioButton(&df.Display, df.ID_MONO);
    } else if (df.cfg.mono == 2) {
        df.PushRadioButton(&df.Display, df.ID_REVERSE);
    } else {
        df.PushRadioButton(&df.Display, df.ID_COLOR);
    }

    if (df.SCREENHEIGHT != df.cfg.ScreenLines) {
//        SetScreenHeight(df.cfg.ScreenLines); // This method currently does nothing.
        if ((win.WindowHeight() == ScreenHeight) or
                (df.SCREENHEIGHT-1 < win.GetBottom()))    {
            win.SetWindowHeight(df.SCREENHEIGHT);
            win.SetBottom(win.GetTop()+win.WindowHeight()-1);
            wnd.*.RestoredRC = win.WindowRect();
        }
    }
    SelectColors(win);
    // INCLUDE_WINDOWOPTIONS
//    df.SelectBorder(wnd);
//    df.SelectTitle(wnd);
//    df.SelectStatusBar(wnd);

    const rtn = root.BaseWndProc(df.APPLICATION, wnd, df.CREATE_WINDOW, 0, 0);
//    if (wnd->extension != NULL)
//        CreateMenu(wnd);
//    CreateStatusBar(wnd);
    _ = df.SendMessage(null, df.SHOW_MOUSE, 0, 0);
    return rtn;
}

// ----- set up colors for the application window ------
fn SelectColors(win: *Window) void {
//    var clr = df.cfg.clr;
//    if (RadioButtonSetting(&Display, ID_MONO))
//        cfg.mono = 1;   /* mono */
//    else if (RadioButtonSetting(&Display, ID_REVERSE))
//        cfg.mono = 2;   /* mono reverse */
//    else
//        cfg.mono = 0;   /* color */
//
//    if (cfg.mono == 1)
//        memcpy(cfg.clr, bw, sizeof bw);
//    else if (cfg.mono == 2)
//        memcpy(cfg.clr, reverse, sizeof reverse);
//    else
//        memcpy(cfg.clr, color, sizeof color);
        @memcpy(&df.cfg.clr, &df.color);
    DoWindowColors(win.win);
}

fn DoWindowColors(wnd: df.WINDOW) void {
    df.InitWindowColors(wnd);
    var cwnd:df.WINDOW = df.FirstWindow(wnd);
    while (cwnd != null) {
        DoWindowColors(cwnd);
        if ((df.GetClass(cwnd) == df.TEXT) and df.GetText(cwnd) != null) {
            _ = df.SendMessage(cwnd, df.CLEARTEXT, 0, 0);
        }
        cwnd = df.NextWindow(cwnd);
    }
}
