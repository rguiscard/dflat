const std = @import("std");
const root = @import("root.zig");
const df = @import("ImportC.zig").df;
const command = @import("Commands.zig").Command;
const msg = @import("Message.zig");
const Window = @import("Window.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

var SysMenuOpen = false;
const MAXCONTROLS = 30;
var dbs = std.ArrayList(*df.DBOX).init(allocator);

pub const DLBox = struct {
    HelpName: []const u8,
    dwnd: df.DIALOGWINDOW,
    ctl: [MAXCONTROLS+1]?df.CTLWINDOW = .{null} ** (MAXCONTROLS+1),

    pub fn addControl(self: DLBox, ty: df.CLASS, tx:?[]const u8, x: c_int, y: c_int, w: c_int, h: c_int, c: c_int) void {
        var box = self;

        for(self.ctl, 0..) |ctl, i| {
            if (ctl == null) {
                const txt = if ((ty == df.EDITBOX) or (ty == df.COMBOBOX)) null else if (tx) |t| @constCast(t.ptr) else null;
                const ctl_wnd:df.CTLWINDOW = .{
                    .dwnd = .{.title = null, .x = x, .y = y, .h = h, .w = w},
                    .Class = ty,
                    .itext = txt,
                    .command = c,
                    .help = null, // should be #c, c in text
                    .isetting = if (ty == df.BUTTON) df.ON else df.OFF,
                    .setting = df.OFF,
                    .wnd = null,
                };

                box.ctl[i] = ctl_wnd;
                break;
            }
        }
    }
};

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
                        attrib,
                        root.global_allocator);
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
//    const db:*df.DBOX = @alignCast(@ptrCast(wnd.*.extension));
//    const cmd:c_int = @intCast(p1);
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
//            if ((int)p2 != 0)
//                return TRUE;
//            return DisplayHelp(wnd, db->HelpName);
        },
        else => {
        }
    }
    return df.FALSE;
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
//            if (LeftButtonMsg(wnd, p1, p2))
//                return TRUE;
        },
        df.KEYBOARD => {
//            if (KeyboardMsg(wnd, p1, p2))
//                return TRUE;
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
//                        if ((int)p1 && wnd->dfocus != NULL && isVisible(wnd))
//                                return SendMessage(wnd->dfocus, SETFOCUS, TRUE, 0);
//            return df.cDialogProc(wnd, message, p1, p2_new);
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
pub fn DialogBox(wnd: df.WINDOW, db:*df.DBOX, Modal: bool,
                 wndproc: ?*const fn (wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int) bool {
    var rtn = false;
    const x = db.*.dwnd.x;
    const y = db.*.dwnd.y;

    var save:c_int = 0;
    if (Modal) {
        save = df.SAVESELF;
    }

    const ttl:[]const u8 =  std.mem.span(db.*.dwnd.title);
    var win = Window.create(df.DIALOG,
                        ttl,
                        x, y,
                        db.*.dwnd.h,
                        db.*.dwnd.w,
                        db,
                        wnd,
                        wndproc,
                        save,
                        root.global_allocator);
    const DialogWnd = win.win;

    _ = win.sendMessage(msg.Message.SETFOCUS, df.TRUE, 0);
    DialogWnd.*.Modal = if (Modal) 1 else 0;
    FirstFocus(db);
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
//            if (CtlKeyboardMsg(wnd, p1, p2))
//                return TRUE;
        },
        df.PAINT => {
//            FixColors(wnd);
//            if (GetClass(wnd) == EDITBOX ||
//                    GetClass(wnd) == LISTBOX ||
//                        GetClass(wnd) == TEXTBOX)
//                SetScrollBars(wnd);
        },
        df.BORDER => {
//                        FixColors(wnd);
//            if (GetClass(wnd) == EDITBOX)    {
//                WINDOW oldFocus = inFocus;
//                inFocus = NULL;
//                DefaultWndProc(wnd, msg, p1, p2);
//                inFocus = oldFocus;
//                return TRUE;
//            }
        },
        df.SETFOCUS => {
            const db:?*df.DBOX = if (df.GetParent(wnd) != null) @alignCast(@ptrCast(df.GetParent(wnd).*.extension)) else null;
            const pwnd = df.GetParent(wnd);
            if (p1 > 0) {
//                                WINDOW oldFocus = inFocus;
//                                if (pwnd && GetClass(oldFocus) != APPLICATION &&
//                                                !isAncestor(inFocus, pwnd))     {
//                                        inFocus = NULL;
//                                        SendMessage(oldFocus, BORDER, 0, 0);
//                                        SendMessage(pwnd, SHOW_WINDOW, 0, 0);
//                                        inFocus = oldFocus;
//                                        ClearVisible(oldFocus);
//                                }
//                                if (GetClass(oldFocus) == APPLICATION &&
//                                                NextWindow(pwnd) != NULL)
//                                        pwnd->wasCleared = FALSE;
//                DefaultWndProc(wnd, msg, p1, p2);
//                                SetVisible(oldFocus);
//                                if (pwnd != NULL)       {
//                                        pwnd->dfocus = wnd;
//                        SendMessage(pwnd, COMMAND,
//                        inFocusCommand(db), ENTERFOCUS);
//                                }
//                return TRUE;
                return df.ControlProc(wnd, message, p1, p2);
            } else {
                _ = df.SendMessage(pwnd, df.COMMAND,
                    inFocusCommand(db), df.LEAVEFOCUS);
            }
        },
        df.CLOSE_WINDOW => {
//            CtlCloseWindowMsg(wnd);
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

// ---- change the focus to the first control ---
fn FirstFocus(db:*df.DBOX) void {
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
