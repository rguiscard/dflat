const std = @import("std");
const root = @import("root.zig");
const df = @import("ImportC.zig").df;
const command = @import("Commands.zig").Command;
const msg = @import("Message.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const checkbox = @import("CheckBox.zig");
const helpbox = @import("HelpBox.zig");

var SysMenuOpen = false;
const MAXCONTROLS = 30;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
var dbs = std.ArrayList(*df.DBOX).init(allocator);

// Handle DBOX from dflat
box: *df.DBOX,

/// `@This()` can be used to refer to this struct type. In files with fields, it is quite common to
/// name the type here, so it can be easily referenced by other declarations in this file.
const TopLevelFields = @This();

// use create() after this one to create associate windows
pub fn init(box: *df.DBOX) TopLevelFields {
    return .{
        .box = box,
    };
}

pub fn setCheckBox(self: *TopLevelFields, cmd: command) void {
    const c:c_uint = @intCast(@intFromEnum(cmd));
    df.SetCheckBox(self.box,  c);
}

pub fn checkBoxSetting(self: *TopLevelFields, cmd: command) bool {
    const c:c_uint = @intCast(@intFromEnum(cmd));
    return (checkbox.CheckBoxSetting(self.box,  c) > 0);
//    return (df.CheckBoxSetting(self.box,  c) > 0);
}


pub fn getEditBoxText(self: *TopLevelFields, cmd: command) [*c]u8 {
    const c:c_uint = @intCast(@intFromEnum(cmd));
    return df.GetEditBoxText(self.box,  c);
}

pub fn deinit(self: *TopLevelFields) void {
    _ = self;
}

// -------- CREATE_WINDOW Message ---------
fn CreateWindowMsg(wnd: df.WINDOW, p1: df.PARAM, p2: df.PARAM) c_int {
    const db:*df.DBOX = @alignCast(@ptrCast(wnd.*.extension));
//    const ct:*df.CTLWINDOW = @ptrCast(&db.*.ctl[0]);
//    var ct = db.*.ctl;
    var rtn:c_int = 0;
    var idx:isize = -1;

    // ---- build a table of processed dialog boxes ----
    for (dbs.items, 0..) |item, i| {
        if (db == item) {
            idx = @intCast(i);
            break;
        }
    }
    if (idx < 0) { // not found
        if (dbs.append(db)) {
        } else |_| { // error
        }
    }
    rtn = root.BaseWndProc(df.DIALOG, wnd, df.CREATE_WINDOW, p1, p2);

    for(0..MAXCONTROLS) |i| {
        const ctl:*df.CTLWINDOW = @ptrCast(&db.*.ctl[i]);
        if (ctl.*.Class == 0) { // Class as 0 is used as end of array
            break;
        }
        var attrib:c_int = 0;
        if (wnd.*.attrib & df.NOCLIP > 0)
            attrib = attrib | df.NOCLIP;
        if (wnd.*.Modal > 0)
            attrib = attrib | df.SAVESELF;
        ctl.*.setting = ctl.*.isetting;
        if ((ctl.*.Class == df.EDITBOX) and (ctl.*.dwnd.h > 1)) {
            attrib = attrib | (df.MULTILINE | df.HASBORDER);
        } else if ((ctl.*.Class == df.LISTBOX or ctl.*.Class == df.TEXTBOX) and ctl.*.dwnd.h > 2) {
            attrib = attrib | df.HASBORDER;
        }
        const win:*Window = @constCast(@fieldParentPtr("win", &wnd));
        var cwnd = Window.create(ctl.*.Class,
                        if (ctl.*.dwnd.title) |t| std.mem.span(t) else null,
                        @intCast(ctl.*.dwnd.x+win.GetClientLeft()),
                        @intCast(ctl.*.dwnd.y+win.GetClientTop()),
                        ctl.*.dwnd.h,
                        ctl.*.dwnd.w,
                        ctl,
                        wnd,
                        ControlProc,
                        attrib);
        if ((ctl.*.Class == df.EDITBOX or ctl.*.Class == df.TEXTBOX or
                ctl.*.Class == df.COMBOBOX) and
                    ctl.*.itext != null) {
            _ = cwnd.sendTextMessage(msg.Message.SETTEXT, std.mem.span(ctl.*.itext), 0);
        }
    }
    return rtn;
}

// -------- COMMAND Message --------- 
fn CommandMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) df.BOOL {
    switch (p1) {
        df.ID_OK, df.ID_CANCEL => {
            if (p2 != 0)
                return df.TRUE;
            wnd.*.ReturnCode = @intCast(p1);
            if (wnd.*.Modal > 0) {
                _ = df.PostMessage(wnd, df.ENDDIALOG, 0, 0);
            } else {
                _ = df.SendMessage(wnd, df.CLOSE_WINDOW, df.TRUE, 0);
            }
            return df.TRUE;
        },
        df.ID_HELP => {
            if (p2 != 0)
                return df.TRUE;
            const db:*df.DBOX = @alignCast(@ptrCast(wnd.*.extension));
            const rtn:c_uint = @intCast(helpbox.DisplayHelp(wnd, std.mem.span(db.*.HelpName)));
            return rtn;
        },
        else => {
        }
    }
    return df.FALSE;
}

// -------- LEFT_BUTTON Message ---------
fn LeftButtonMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) c_int {
    if ((df.WindowSizing>0) or (df.WindowMoving>0))
        return df.TRUE;

    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));
    if (df.HitControlBox(wnd, p1-win.GetLeft(), p2-win.GetTop())) {
        df.PostMessage(wnd, df.KEYBOARD, ' ', df.ALTKEY);
        return df.TRUE;
    }
//    const db:*df.DBOX = @alignCast(@ptrCast(wnd.*.extension));
//    CTLWINDOW *ct = db->ctl;
//    while (ct->Class)    {
//        WINDOW cwnd = ct->wnd;
//        if (ct->Class == COMBOBOX)    {
//            if (p2 == GetTop(cwnd))    {
//                if (p1 == GetRight(cwnd)+1)    {
//                    SendMessage(cwnd, LEFT_BUTTON, p1, p2);
//                    return TRUE;
//                }
//            }
//            if (GetClass(inFocus) == LISTBOX)
//                SendMessage(wnd, SETFOCUS, TRUE, 0);
//        }
//        else if (ct->Class == SPINBUTTON)    {
//            if (p2 == GetTop(cwnd))    {
//                if (p1 == GetRight(cwnd)+1 ||
//                        p1 == GetRight(cwnd)+2)    {
//                    SendMessage(cwnd, LEFT_BUTTON, p1, p2);
//                    return TRUE;
//                }
//            }
//        }
//        ct++;
//    }
    return df.FALSE;
}

fn KeyboardMsg(wnd:df.WINDOW, p1:df.PARAM, p2:df.PARAM) c_uint {
//    DBOX *db = wnd->extension;
//    CTLWINDOW *ct;

    _ = p2;

    if ((df.WindowMoving>0) or (df.WindowSizing>0))
        return df.FALSE;
    switch (p1) {
//        case SHIFT_HT:
//        case BS:
//        case UP:
//            PrevFocus(db);
//            break;
//        case ALT_F6:
//        case '\t':
//        case FWD:
//        case DN:
//            NextFocus(db);
//            break;
//        case ' ':
//            if (((int)p2 & ALTKEY) &&
//                    TestAttribute(wnd, CONTROLBOX))    {
//                SysMenuOpen = TRUE;
//                BuildSystemMenu(wnd);
//                                return TRUE;
//            }
//            break;
//        case CTRL_F4:
//        case ESC:
//            SendMessage(wnd, COMMAND, ID_CANCEL, 0);
//            break;
//#ifdef INCLUDE_HELP
//        case F1:
//            ct = GetControl(inFocus);
//            if (ct != NULL)
//                if (DisplayHelp(wnd, ct->help))
//                    return TRUE;
//            break;
//#endif
//        default:
//            /* ------ search all the shortcut keys ----- */
//            if (dbShortcutKeys(db, (int) p1))
//                                return TRUE;
//            break;
          else => {
              // ------ search all the shortcut keys -----
//            if (dbShortcutKeys(db, (int) p1))
//                                return TRUE;
          }
    }
    return wnd.*.Modal;
}

// ----- window-processing module, DIALOG window class -----
pub export fn DialogProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    var p2_new = p2;
    var rtn:c_int = 0;

    switch (message) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(wnd, p1, p2);
        },
        df.SHIFT_CHANGED => {
            if (wnd.*.Modal > 0)
                return df.TRUE;
        },
        df.LEFT_BUTTON => {
            if (LeftButtonMsg(wnd, p1, p2) > 0)
                return df.TRUE;
        },
        df.KEYBOARD => {
            if (KeyboardMsg(wnd, p1, p2) > 0)
                return df.TRUE;
        },
        df.CLOSE_POPDOWN => {
            SysMenuOpen = false;
        },
        df.LB_SELECTION, df.LB_CHOOSE => {
            if (SysMenuOpen)
                return df.TRUE;
            if (wnd.*.extension) |extension| {
                const db:*df.DBOX = @alignCast(@ptrCast(extension));
                _ = df.SendMessage(wnd, df.COMMAND, inFocusCommand(db), message);
            }
        },
        df.SETFOCUS => {
            if ((p1 != 0) and (wnd.*.dfocus != null) and (df.isVisible(wnd) > 0)) {
                return df.SendMessage(wnd.*.dfocus, df.SETFOCUS, df.TRUE, 0);
            }
        },
        df.COMMAND => {
            if (CommandMsg(wnd, p1, p2) > 0)
                return df.TRUE;
        },
        df.PAINT => {
            p2_new = df.TRUE;
        },
        df.MOVE, df.SIZE => {
            rtn = root.BaseWndProc(df.DIALOG, wnd, message, p1, p2);
            if ((wnd.*.dfocus != null) and (df.isVisible(wnd) > 0))
                _ = df.SendMessage(wnd.*.dfocus, df.SETFOCUS, df.TRUE, 0);
            return rtn;
        },
        df.CLOSE_WINDOW => {
            if (p1 == 0) {
                _ = df.SendMessage(wnd, df.COMMAND, df.ID_CANCEL, 0);
                return df.TRUE;
            }
        },
        else => {
        }
    }
    return root.BaseWndProc(df.DIALOG, wnd, message, p1, p2_new);
}

// ------- create and execute a dialog box ----------
// Use this one after init()
pub fn create(self: *TopLevelFields, wnd: df.WINDOW, Modal: bool,
                 wndproc: ?*const fn (wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int) bool {
    var rtn = false;
    const x = self.box.*.dwnd.x;
    const y = self.box.*.dwnd.y;

    var save:c_int = 0;
    if (Modal) {
        save = df.SAVESELF;
    }

    const ttl:[]const u8 =  std.mem.span(self.box.*.dwnd.title);
    var win = Window.create(df.DIALOG,
                        ttl,
                        x, y,
                        self.box.*.dwnd.h,
                        self.box.*.dwnd.w,
                        self.box,
                        wnd,
                        wndproc,
                        save);
    const DialogWnd = win.win;

    _ = win.sendMessage(msg.Message.SETFOCUS, df.TRUE, 0);
    DialogWnd.*.Modal = if (Modal) 1 else 0;
    self.FirstFocus();
    df.PostMessage(DialogWnd, df.INITIATE_DIALOG, 0, 0);
    if (Modal) {
        _ = win.sendMessage(msg.Message.CAPTURE_MOUSE, 0, 0);
        _ = win.sendMessage(msg.Message.CAPTURE_KEYBOARD, 0, 0);
        while (msg.dispatch_message()) {
        }
        rtn = (DialogWnd.*.ReturnCode == df.ID_OK);
        _ = win.sendMessage(msg.Message.RELEASE_MOUSE, 0, 0);
        _ = win.sendMessage(msg.Message.RELEASE_KEYBOARD, 0, 0);
        _ = win.sendMessage(msg.Message.CLOSE_WINDOW, df.TRUE, 0);
    }
    return rtn;
}

// ----- return command code of in-focus control window ----
fn inFocusCommand(db:?*df.DBOX) c_int {
    if (db) |box| {
        for(box.*.ctl) |ctl| {
            if (ctl.Class == 0)
                break;
            const w:df.WINDOW = @alignCast(@ptrCast(ctl.wnd));
            if (w == df.inFocus) {
                return ctl.command;
            }
        }
    }
    return -1;
}

// -- generic window processor used by dialog box controls --
fn ControlProc(wnd:df.WINDOW, message: df.MESSAGE, p1:df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    if (wnd == null)
        return df.FALSE;

//    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));
//    const db = if (df.GetParent(wnd) != null) df.GetParent(wnd).*.extension else null;

//    DBOX *db;
//
//    db = GetParent(wnd) ? GetParent(wnd)->extension : NULL;

    switch (message) {
        df.CREATE_WINDOW => {
            CtlCreateWindowMsg(wnd);
        },
        df.KEYBOARD => {
            if (df.CtlKeyboardMsg(wnd, p1, p2) > 0)
                return df.TRUE;
        },
        df.PAINT => {
            FixColors(wnd);
            if ((df.GetClass(wnd) == df.EDITBOX) or
                (df.GetClass(wnd) == df.LISTBOX) or
                (df.GetClass(wnd) == df.TEXTBOX)) {
                SetScrollBars(wnd);
            }
        },
        df.BORDER => {
            FixColors(wnd);
            if (df.GetClass(wnd) == df.EDITBOX) {
                const oldFocus = df.inFocus;
                df.inFocus = null;
                _ = root.DefaultWndProc(wnd, message, p1, p2);
                df.inFocus = oldFocus;
                return df.TRUE;
            }
        },
        df.SETFOCUS => {
            const db:?*df.DBOX = if (df.GetParent(wnd) != null) @alignCast(@ptrCast(df.GetParent(wnd).*.extension)) else null;
            const pwnd = df.GetParent(wnd);
            if (p1 > 0) {
                const oldFocus = df.inFocus;
                const oldWin:*Window = @constCast(@fieldParentPtr("win", &oldFocus));
                if ((pwnd != null) and (df.GetClass(oldFocus) != df.APPLICATION) and
                                       (df.isAncestor(df.inFocus, pwnd) == 0)) {
                    df.inFocus = null;
                    _ = df.SendMessage(oldFocus, df.BORDER, 0, 0);
                    _ = df.SendMessage(pwnd, df.SHOW_WINDOW, 0, 0);
                    df.inFocus = oldFocus;
//                    df.ClearVisible(oldFocus);
                    oldWin.ClearVisible();
                }
                if ((df.GetClass(oldFocus) == df.APPLICATION) and
                    df.NextWindow(pwnd) != null) {
                    pwnd.*.wasCleared = df.FALSE;
                }
                _ = root.DefaultWndProc(wnd, message, p1, p2);
//                df.SetVisible(oldFocus);
                oldWin.SetVisible();
                if (pwnd != null) {
                    pwnd.*.dfocus = wnd;
                    _ = df.SendMessage(pwnd, df.COMMAND,
                        inFocusCommand(db), df.ENTERFOCUS);
                }
                return df.TRUE;
//                return df.ControlProc(wnd, message, p1, p2);
            } else {
                _ = df.SendMessage(pwnd, df.COMMAND,
                    inFocusCommand(db), df.LEAVEFOCUS);
            }
        },
        df.CLOSE_WINDOW => {
            df.CtlCloseWindowMsg(wnd);
        },
        else => {
        }
    }
    return root.DefaultWndProc(wnd, message, p1, p2);
}

// ------- CREATE_WINDOW Message (Control) -----
fn CtlCreateWindowMsg(wnd: df.WINDOW) void {
    if (wnd.*.extension) |extension| {
        wnd.*.ct = @alignCast(@ptrCast(extension));

        const ct = wnd.*.ct;
        ct.*.wnd = wnd;
    } else {
        wnd.*.ct = null;
    }
    wnd.*.extension = null;
}

fn FixColors(wnd:df.WINDOW) void {
    const ct = wnd.*.ct;
    if (ct.*.Class != df.BUTTON) {
        if ((ct.*.Class != df.SPINBUTTON) and (ct.*.Class != df.COMBOBOX)) {
            if ((ct.*.Class != df.EDITBOX) and (ct.*.Class != df.LISTBOX)) {
                wnd.*.WindowColors[df.FRAME_COLOR][df.FG] =
                                        df.GetParent(wnd).*.WindowColors[df.FRAME_COLOR][df.FG];
                wnd.*.WindowColors[df.FRAME_COLOR][df.BG] =
                                        df.GetParent(wnd).*.WindowColors[df.FRAME_COLOR][df.BG];
                wnd.*.WindowColors[df.STD_COLOR][df.FG] =
                                        df.GetParent(wnd).*.WindowColors[df.STD_COLOR][df.FG];
                wnd.*.WindowColors[df.STD_COLOR][df.BG] =
                                        df.GetParent(wnd).*.WindowColors[df.STD_COLOR][df.BG];
            }
        }
    }
}

// --- dynamically add or remove scroll bars
//                            from a control window ----
fn SetScrollBars(wnd:df.WINDOW) void {
    const win:*Window = @constCast(@fieldParentPtr("win", &wnd));

    const oldattr = win.GetAttribute();
    if (wnd.*.wlines > win.ClientHeight()) {
        win.AddAttribute(df.VSCROLLBAR);
    } else {
        win.ClearAttribute(df.VSCROLLBAR);
    }
    if (wnd.*.textwidth > win.ClientWidth()) {
        win.AddAttribute(df.HSCROLLBAR);
    } else {
        win.ClearAttribute(df.HSCROLLBAR);
    }
    if (win.GetAttribute() != oldattr)
        _ = win.sendMessage(msg.Message.BORDER, 0, 0);
}


// ---- change the focus to the first control ---
fn FirstFocus(self: *TopLevelFields) void {
    const db = self.box;
    var ct:[*c]df.CTLWINDOW = &db.*.ctl;
    if (ct != null) {
        while ((ct.*.Class == df.TEXT) or (ct.*.Class == df.BOX)) {
            ct = ct + 1;
            if (ct.*.Class == 0)
                return;
        }
        if (ct) |c| {
            const ctl:df.CTLWINDOW = c.*;
            const wnd:df.WINDOW = @ptrCast(@alignCast(ctl.wnd));
            _ = df.SendMessage(wnd, df.SETFOCUS, df.TRUE, 0);
        }
    }
}
