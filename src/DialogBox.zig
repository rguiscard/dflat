const std = @import("std");
const root = @import("root.zig");
const df = @import("ImportC.zig").df;
const command = @import("Commands.zig").Command;
const msg = @import("Message.zig");
const Window = @import("Window.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const MAXCONTROLS = 30;

pub const DLBox = struct {
    HelpName: []const u8,
    dwnd: df.DIALOGWINDOW,
    ctl: [MAXCONTROLS+1]?df.CTLWINDOW = .{null} ** (MAXCONTROLS+1),

    pub fn addControl(self: DLBox, ty: df.CLASS, tx:?[]const u8, x: c_int, y: c_int, w: c_int, h: c_int, c: c_int) void {
        var box = self;

        for(self.ctl, 0..) |ctl, i| {
            if (ctl == null) {
                const txt = if ((ty == df.EDITBOX) or (ty == df.COMBOBOX)) null else if (tx) |t| t.ptr else null;
                const ctl_wnd:df.CTLWINDOW = .{
                    .dwnd = .{.title = null, .x = x, .y = y, .h = h, .w = w},
                    .Class = ty,
                    .itext = @constCast(txt),
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
