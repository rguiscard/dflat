const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const log = @import("Log.zig");
const checkbox = @import("CheckBox.zig");
//const DialogBox = @import("DialogBox.zig");
const msg = @import("Message.zig").Message;
const helpbox = @import("HelpBox.zig");

var ScreenHeight:c_int = 0;
var WindowSel:c_int = 0;

pub export fn ApplicationProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));

    switch (message) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(win);
        },
        df.HIDE_WINDOW => {
            if (wnd == df.inFocus)
                df.inFocus = null;
        },
        df.ADDSTATUS => {
            AddStatusMsg(win, p1);
            return df.TRUE;
        },
        df.SETFOCUS => {
//            if ((int)p1 == (inFocus != wnd))    {
            if (((df.inFocus != wnd) and (p1 != 0)) or 
                ((df.inFocus == wnd) and (p1 == 0))) {
                SetFocusMsg(wnd, if (p1 == 0) false else true);
                return df.TRUE;
            }
        },
        df.SIZE => {
            SizeMsg(win, p1, p2);
            return df.TRUE;
        },
        df.MINIMIZE => {
            return df.TRUE;
        },
        df.KEYBOARD => {
            return KeyboardMsg(win, p1, p2);
        },
        df.SHIFT_CHANGED => {
            ShiftChangedMsg(win, p1);
            return df.TRUE;
        },
        df.PAINT => {
            if (df.isVisible(wnd) > 0)    {
//                int cl = cfg.Texture ? APPLCHAR : ' ';
                var cl:u8 = ' ';
                if (df.cfg.Texture > 0)
                    cl = df.APPLCHAR;
                const pptr:usize = @intCast(p1);
                df.ClearWindow(wnd, @ptrFromInt(pptr), cl);
            }
            return df.TRUE;
        },
        df.COMMAND => {
            CommandMsg(win, p1, p2);
            return df.TRUE;
        },
        df.CLOSE_WINDOW => {
            return CloseWindowMsg(win);
        },
        else => {
        }
    }
    return root.BaseWndProc(df.APPLICATION, wnd, message, p1, p2);
}

// --------- ADDSTATUS Message ----------
fn AddStatusMsg(win: *Window, p1: df.PARAM) void {
    const wnd = win.win;
    if (wnd.*.StatusBar != null) {
        var text:?[]const u8 = null;
        if (p1 > 0) {
            const p:usize = @intCast(p1);
            const t:[*c]u8 = @ptrFromInt(p);
            text = std.mem.span(t);
            if (text.?.len == 0) {
                text = null;
            }
        }
        if (text) |_| {
            _ = df.SendMessage(wnd.*.StatusBar, df.SETTEXT, p1, 0);
        } else {
            _ = df.SendMessage(wnd.*.StatusBar, df.CLEARTEXT, 0, 0);
        }
        _ = df.SendMessage(wnd.*.StatusBar, df.PAINT, 0, 0);
    }
}

// -------- SETFOCUS Message --------
fn SetFocusMsg(wnd:df.WINDOW, p1:bool) void {
    if (p1)
        _ = df.SendMessage(df.inFocus, df.SETFOCUS, df.FALSE, 0);
    df.inFocus = if (p1) wnd else null;
    _ = df.SendMessage(null, df.HIDE_CURSOR, 0, 0);
    if (df.isVisible(wnd) > 0) {
        _ = df.SendMessage(wnd, df.BORDER, 0, 0);
    } else {
        _ = df.SendMessage(wnd, df.SHOW_WINDOW, 0, 0);
    }
}

// ------- SIZE Message --------
fn SizeMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    var WasVisible = false;
    WasVisible = (df.isVisible(win.win) > 0);
    if (WasVisible)
        _ = win.sendMessage(msg.HIDE_WINDOW, 0, 0);
    var p1_new = p1;
    if (p1-win.GetLeft() < 30)
        p1_new = win.GetLeft() + 30;
    _ = root.BaseWndProc(df.APPLICATION, win.win, df.SIZE, p1_new, p2);
    CreateMenu(win);
    CreateStatusBar(win);
    if (WasVisible)
        _ = win.sendMessage(msg.SHOW_WINDOW, 0, 0);
}


// ----------- KEYBOARD Message ------------
fn KeyboardMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) c_int {
    const wnd = win.win;
    _ = wnd;
    _ = p1;
    _ = p2;
//    if (WindowMoving || WindowSizing || (int) p1 == F1)
//        return BaseWndProc(APPLICATION, wnd, KEYBOARD, p1, p2);
//    switch ((int) p1)    {
//        case ALT_F4:
//                        if (TestAttribute(wnd, CONTROLBOX))
//                    PostMessage(wnd, CLOSE_WINDOW, 0, 0);
//            return TRUE;
// INCLUDE_MULTI_WINDOWS
//        case ALT_F6:
//            SetNextFocus();
//            return TRUE;

//        case ALT_HYPHEN:
//                        if (TestAttribute(wnd, CONTROLBOX))
//                    BuildSystemMenu(wnd);
//            return TRUE;
//        default:
//            break;
//    }
//    PostMessage(wnd->MenuBarWnd, KEYBOARD, p1, p2);
    return df.TRUE;
}

// --------- SHIFT_CHANGED Message --------
fn ShiftChangedMsg(win:*Window, p1:df.PARAM) void {
    const wnd = win.win;
    _ = wnd;
    _ = p1;
//        extern BOOL AltDown;
//    if ((int)p1 & ALTKEY)
//        AltDown = TRUE;
//    else if (AltDown)    {
//        AltDown = FALSE;
//        if (wnd->MenuBarWnd != inFocus)
//            SendMessage(NULL, HIDE_CURSOR, 0, 0);
//        SendMessage(wnd->MenuBarWnd, KEYBOARD, F10, 0);
//    }
}

// -------- COMMAND Message -------
fn CommandMsg(win:*Window, p1:df.PARAM, p2:df.PARAM) void {
    const wnd = win.win;
    const p:usize = @intCast(p1);
    switch (p) {
        df.ID_EXIT, df.ID_SYSCLOSE => {
            df.PostMessage(wnd, df.CLOSE_WINDOW, 0, 0);
        },
        df.ID_HELP => {
            _ = df.DisplayHelp(wnd, df.DFlatApplication);
        },
        df.ID_HELPHELP => {
            _ = helpbox.DisplayHelp(wnd, "HelpHelp");
        },
        df.ID_EXTHELP => {
            _ = helpbox.DisplayHelp(wnd, "ExtHelp");
        },
        df.ID_KEYSHELP => {
            _ = helpbox.DisplayHelp(wnd, "KeysHelp");
        },
        df.ID_HELPINDEX => {
            _ = helpbox.DisplayHelp(wnd, "HelpIndex");
        },
        df.ID_LOG => {
            log.MessageLog(wnd);
        },
        df.ID_DOS => {
//            df.ShellDOS(wnd);
        },
        df.ID_DISPLAY => {
//            if (DialogBox(wnd, &Display, TRUE, NULL))    {
//                                if (inFocus == wnd->MenuBarWnd || inFocus == wnd->StatusBar)
//                                        oldFocus = ApplicationWindow;
//                                else
//                                        oldFocus = inFocus;
//                SendMessage(wnd, HIDE_WINDOW, 0, 0);
//                SelectColors(wnd);
//                SelectLines(wnd);

// INCLUDE_WINDOWOPTIONS
//                SelectBorder(wnd);
//                SelectTitle(wnd);
//                SelectStatusBar(wnd);
//                SelectTexture();

//                CreateMenu(wnd);
//                CreateStatusBar(wnd);
//                SendMessage(wnd, SHOW_WINDOW, 0, 0);
//                            SendMessage(oldFocus, SETFOCUS, TRUE, 0);
//            }
        },
        df.ID_WINDOW => {
//            df.ChooseWindow(wnd, df.CurrentMenuSelection-2);
        },
        df.ID_CLOSEALL => {
            CloseAll(win, false);
        },
        df.ID_MOREWINDOWS => {
//            df.MoreWindows(wnd);
        },
        df.ID_SAVEOPTIONS => {
//            df.SaveConfig();
        },
        df.ID_SYSRESTORE, df.ID_SYSMINIMIZE, df.ID_SYSMAXIMIZE, df.ID_SYSMOVE, df.ID_SYSSIZE => {
            _ = root.BaseWndProc(df.APPLICATION, wnd, df.COMMAND, p1, p2);
        },
        else => {
            if ((df.inFocus != wnd.*.MenuBarWnd) and (df.inFocus != wnd)) {
                df.PostMessage(df.inFocus, df.COMMAND, p1, p2);
            }
        }
    }
}

// --------- CLOSE_WINDOW Message --------
fn CloseWindowMsg(win:*Window) c_int {
    const wnd = win.win;
    CloseAll(win, true);
    WindowSel = 0;
    df.PostMessage(null, df.STOP, 0, 0);

    const rtn = root.BaseWndProc(df.APPLICATION, wnd, df.CLOSE_WINDOW, 0, 0);
    if (ScreenHeight != df.SCREENHEIGHT)
        SetScreenHeight(ScreenHeight);

    // UnLoadHelpFile();
    df.ApplicationWindow = null;
    return rtn;
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
        SetScreenHeight(df.cfg.ScreenLines); // This method currently does nothing.
        if ((win.WindowHeight() == ScreenHeight) or
                (df.SCREENHEIGHT-1 < win.GetBottom()))    {
            win.SetWindowHeight(df.SCREENHEIGHT);
            win.SetBottom(win.GetTop()+win.WindowHeight()-1);
            wnd.*.RestoredRC = win.WindowRect();
        }
    }
    SelectColors(win);
    // INCLUDE_WINDOWOPTIONS
    SelectBorder(win);
    SelectTitle(win);
    SelectStatusBar(win);

    const rtn = root.BaseWndProc(df.APPLICATION, wnd, df.CREATE_WINDOW, 0, 0);
    if (wnd.*.extension != null) {
        CreateMenu(win);
    }

    // FIXME: call this method result memory leak if:
    // 1. open a document
    // 2. exit the application
    // It will not happen for exiting after new document or no document
    // It will not happen for c version (calling df.ApplicationProc in src/Classes.zig).
    CreateStatusBar(win);

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

// ----- select the screen texture -----
fn SelectTexture() void {
//    df.cfg.Texture = df.CheckBoxSetting(&df.Display, df.ID_TEXTURE);
    df.cfg.Texture = checkbox.CheckBoxSetting(&df.Display, df.ID_TEXTURE);
}

// -- select whether the application screen has a border --
fn SelectBorder(win: *Window) void {
//    df.cfg.Border = df.CheckBoxSetting(&df.Display, df.ID_BORDER);
    df.cfg.Border = checkbox.CheckBoxSetting(&df.Display, df.ID_BORDER);
    if (df.cfg.Border > 0) {
        win.AddAttribute(df.HASBORDER);
    } else {
        win.ClearAttribute(df.HASBORDER);
    }
}

// select whether the application screen has a status bar
fn SelectStatusBar(win: *Window) void {
//    df.cfg.StatusBar = df.CheckBoxSetting(&df.Display, df.ID_STATUSBAR);
    df.cfg.StatusBar = checkbox.CheckBoxSetting(&df.Display, df.ID_STATUSBAR);
    if (df.cfg.StatusBar > 0) {
        win.AddAttribute(df.HASSTATUSBAR);
    } else {
        win.ClearAttribute(df.HASSTATUSBAR);
    }
}

// select whether the application screen has a title bar
fn SelectTitle(win: *Window) void {
//    df.cfg.Title = df.CheckBoxSetting(&df.Display, df.ID_TITLE);
    df.cfg.Title = checkbox.CheckBoxSetting(&df.Display, df.ID_TITLE);
    if (df.cfg.Title > 0) {
        win.AddAttribute(df.HASTITLEBAR);
    } else {
        win.ClearAttribute(df.HASTITLEBAR);
    }
}

// -------- Create the menu bar --------
fn CreateMenu(win: *Window) void {
    const wnd = win.win;
    win.AddAttribute(df.HASMENUBAR);
    if (wnd.*.MenuBarWnd != null) {
        _ = df.SendMessage(wnd.*.MenuBarWnd, df.CLOSE_WINDOW, 0, 0);
    }
    var mwnd = Window.create(df.MENUBAR,
                        null,
                        @intCast(win.GetClientLeft()),
                        @intCast(win.GetClientTop()-1),
                        1,
                        @intCast(win.ClientWidth()),
                        null,
                        wnd,
                        null,
                        0,
                        root.global_allocator);

    win.win.*.MenuBarWnd = mwnd.win;

    const ext:df.PARAM = @intCast(@intFromPtr(wnd.*.extension));
    _ = df.SendMessage(wnd.*.MenuBarWnd, df.BUILDMENU, ext,0);
    mwnd.AddAttribute(df.VISIBLE);
}

// ----------- Create the status bar -------------
fn CreateStatusBar(win: *Window) void {
    const wnd = win.win;
    if (wnd.*.StatusBar != null)    {
        _ = df.SendMessage(wnd.*.StatusBar, df.CLOSE_WINDOW, 0, 0);
        win.win.*.StatusBar = null;
    }
    if (win.TestAttribute(df.HASSTATUSBAR)) {
        var sbar = Window.create(df.STATUSBAR,
                            null,
                            @intCast(win.GetClientLeft()),
                            @intCast(win.GetBottom()),
                            1,
                            @intCast(win.ClientWidth()),
                            null,
                            wnd,
                            null,
                            0,
                            root.global_allocator);
        win.win.*.StatusBar = sbar.win;
        sbar.AddAttribute(df.VISIBLE);
    }
}

// ---- set the screen height in the video hardware ----
fn SetScreenHeight(height: c_int) void {
    _ = height;
    // not implemented originally
//#if 0   /* display size changes not supported */
//        SendMessage(NULL, SAVE_CURSOR, 0, 0);
//
//        /* change display size here */
//
//        SendMessage(NULL, RESTORE_CURSOR, 0, 0);
//        SendMessage(NULL, RESET_MOUSE, 0, 0);
//        SendMessage(NULL, SHOW_MOUSE, 0, 0);
//    }
//#endif
}

// -------- return the name of a document window -------
//static char *WindowName(WINDOW wnd)
//{
//    if (GetTitle(wnd) == NULL)    {
//        if (GetClass(wnd) == DIALOG)
//            return ((DBOX *)(wnd->extension))->HelpName;
//        else
//            return "Untitled";
//    }
//    else
//        return GetTitle(wnd);
//}
// ----------- Prepare the Window menu ------------ */
//void PrepWindowMenu(void *w, struct Menu *mnu)
//
//  WINDOW wnd = w;
//  struct PopDown *p0 = mnu->Selections;
//  struct PopDown *pd = mnu->Selections + 2;
//  struct PopDown *ca = mnu->Selections + 13;
//  int MenuNo = 0;
//  WINDOW cwnd;
//  mnu->Selection = 0;
//  oldFocus = NULL;
//  if (GetClass(wnd) != APPLICATION)    {
//      oldFocus = wnd;
//      /* ----- point to the APPLICATION window ----- */
//              if (ApplicationWindow == NULL)
//                      return;
//              cwnd = FirstWindow(ApplicationWindow);
//      /* ----- get the first 9 document windows ----- */
//      while (cwnd != NULL && MenuNo < 9)    {
//          if (isVisible(cwnd) && GetClass(cwnd) != MENUBAR &&
//                  GetClass(cwnd) != STATUSBAR) {
//              /* --- add the document window to the menu --- */
// #if MSDOS | ELKS
//                strncpy(Menus[MenuNo]+4, WindowName(cwnd), 20);
// #endif
//              pd->SelectionTitle = Menus[MenuNo];
//              if (cwnd == oldFocus)    {
//                  /* -- mark the current document -- */
//                  pd->Attrib |= CHECKED;
//                  mnu->Selection = MenuNo+2;
//              }
//              else
//                  pd->Attrib &= ~CHECKED;
//              pd++;
//              MenuNo++;
//          }
//                      cwnd = NextWindow(cwnd);
//      }
//  }
//  if (MenuNo)
//      p0->SelectionTitle = "~Close all";
//  else
//      p0->SelectionTitle = NULL;
//  if (MenuNo >= 9)    {
//      *pd++ = *ca;
//      if (mnu->Selection == 0)
//          mnu->Selection = 11;
//  }
//  pd->SelectionTitle = NULL;
//

// window processing module for the More Windows dialog box */
//static int WindowPrep(WINDOW wnd,MESSAGE msg,PARAM p1,PARAM p2)
//{
//    switch (msg)    {
//        case INITIATE_DIALOG:    {
//            WINDOW wnd1;
//            WINDOW cwnd = ControlWindow(&Windows,ID_WINDOWLIST);
//            int sel = 0;
//            if (cwnd == NULL)
//                return FALSE;
//                        wnd1 = FirstWindow(ApplicationWindow);
//                        while (wnd1 != NULL)    {
//                if (isVisible(wnd1) && wnd1 != wnd &&
//                                                GetClass(wnd1) != MENUBAR &&
//                                GetClass(wnd1) != STATUSBAR)    {
//                    if (wnd1 == oldFocus)
//                        WindowSel = sel;
//                    SendMessage(cwnd, ADDTEXT,
//                        (PARAM) WindowName(wnd1), 0);
//                    sel++;
//                }
//                                wnd1 = NextWindow(wnd1);
//            }
//            SendMessage(cwnd, LB_SETSELECTION, WindowSel, 0);
//            AddAttribute(cwnd, VSCROLLBAR);
//            PostMessage(cwnd, SHOW_WINDOW, 0, 0);
//            break;
//        }
//        case COMMAND:
//            switch ((int) p1)    {
//                case ID_OK:
//                    if ((int)p2 == 0)
//                        WindowSel = SendMessage(
//                                    ControlWindow(&Windows,
//                                    ID_WINDOWLIST),
//                                    LB_CURRENTSELECTION, 0, 0);
//                    break;
//                case ID_WINDOWLIST:
//                    if ((int) p2 == LB_CHOOSE)
//                        SendMessage(wnd, COMMAND, ID_OK, 0);
//                    break;
//                default:
//                    break;
//            }
//            break;
//        default:
//            break;
//    }
//    return DefaultWndProc(wnd, msg, p1, p2);
//}

///* ---- the More Windows command on the Window menu ---- */
//static void MoreWindows(WINDOW wnd)
//{
//    if (DialogBox(wnd, &Windows, TRUE, WindowPrep))
//        ChooseWindow(wnd, WindowSel);
//}

///* ----- user chose a window from the Window menu
//        or the More Window dialog box ----- */
//static void ChooseWindow(WINDOW wnd, int WindowNo)
//{
//    WINDOW cwnd = FirstWindow(wnd);
//        while (cwnd != NULL)    {
//        if (isVisible(cwnd) &&
//                                GetClass(cwnd) != MENUBAR &&
//                        GetClass(cwnd) != STATUSBAR)
//            if (WindowNo-- == 0)
//                break;
//                cwnd = NextWindow(cwnd);
//    }
//    if (cwnd != NULL)    {
//        SendMessage(cwnd, SETFOCUS, TRUE, 0);
//        if (cwnd->condition == ISMINIMIZED)
//            SendMessage(cwnd, RESTORE, 0, 0);
//    }
//}

// ----- Close all document windows -----
fn CloseAll(win:*Window, closing:bool) void {
    const wnd = win.win;
    _ = df.SendMessage(wnd, df.SETFOCUS, df.TRUE, 0);
    var wnd1:df.WINDOW = df.LastWindow(wnd);
    var wnd2:df.WINDOW = undefined;
    while (wnd1 != null) {
        wnd2 = df.PrevWindow(wnd1);
        if ((df.isVisible(wnd1) > 0) and df.GetClass(wnd1) != df.MENUBAR and
                                        df.GetClass(wnd1) != df.STATUSBAR) {
              wnd.*.attrib = wnd.*.attrib & ~df.VISIBLE; // FIXME, should use ClearVisible() macro
              _ = df.SendMessage(wnd1, df.CLOSE_WINDOW, 0, 0);
        }
        wnd1 = wnd2;
    }
    if (closing == false)
        _ = win.sendMessage(msg.PAINT, 0, 0);
}
