const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");
const msg = @import("Message.zig").Message;


// InputBox and CancelBox were not used. Port them later.

pub fn ErrorMessage(message: []const u8) bool {
    const result = GenericMessage(null, "Error", message, 1, ErrorBoxProc, "   Ok   ", null, df.ID_OK, 0, true);
    return result;
}

// FIXME: potential double free error
pub fn MessageBox(title: []const u8, message: []const u8) bool {
    const result = GenericMessage(null, title, message, 1, MessageBoxProc, "   Ok   ", null, df.ID_OK, 0, true);
    return result;
}

pub fn YesNoBox(message: []const u8) bool {
    const result = GenericMessage(null, "Confirm", message, 2, YesNoBoxProc, "   Yes  ", "   No   ", df.ID_OK, df.ID_CANCEL, true);
    return result;
}

fn GenericMessage(wnd: df.WINDOW, title: ?[]const u8, message:[]const u8, buttonct: c_int,
                  wndproc: *const fn (wnd: df.WINDOW, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int,
                  button1: ?[]const u8, button2: ?[]const u8, c1: c_int, c2: c_int, isModal: bool) bool {
    var mBox = Dialogs.MsgBox;
//    var mBox = df.c_MsgBox();
    const m:[*c]u8 = @constCast(message.ptr);
    var ttl_w:c_int = 0;
    if (title) |t| {
      ttl_w = @intCast(t.len+2);
    }

    mBox.dwnd.title = if (title) |t| @constCast(t.ptr) else null;
    mBox.ctl[0].dwnd.h = df.MsgHeight(m);
    mBox.ctl[0].dwnd.w = @max(@max(df.MsgWidth(m), buttonct*8+buttonct+2),ttl_w);
    mBox.dwnd.h = mBox.ctl[0].dwnd.h+6;
    mBox.dwnd.w = mBox.ctl[0].dwnd.w+4;
    if (buttonct == 1) {
        mBox.ctl[1].dwnd.x = @divFloor((mBox.dwnd.w - 10), 2); // or @divTrunk ?
    } else {
        mBox.ctl[1].dwnd.x = @divFloor((mBox.dwnd.w - 20), 2); // or @divTrunk ?
        mBox.ctl[2].dwnd.x = mBox.ctl[1].dwnd.x + 10;
        mBox.ctl[2].Class = df.BUTTON;
    }

    mBox.ctl[1].dwnd.y = mBox.dwnd.h - 4;
    mBox.ctl[2].dwnd.y = mBox.dwnd.h - 4;
    mBox.ctl[0].itext = m;
    mBox.ctl[1].itext = if (button1) |b| @constCast(b.ptr) else null;
    mBox.ctl[2].itext = if (button2) |b| @constCast(b.ptr) else null;
    mBox.ctl[1].command = c1;
    mBox.ctl[2].command = c2;
    mBox.ctl[1].isetting = df.ON;
    mBox.ctl[2].isetting = df.ON;

    var box = DialogBox.init(&mBox);
    const rtn = box.create(wnd, isModal, wndproc);
//    const rtn = DialogBox.DialogBox(wnd, &mBox, isModal, wndproc);

    mBox.ctl[2].Class = 0;
    return rtn;
}

pub fn MomentaryMessage(message: []const u8, allocator: std.mem.Allocator) Window {
    const m:[*c]u8 = @constCast(message.ptr);

    var win = Window.create(
                    df.TEXTBOX,
                    null,
                    -1,-1,df.MsgHeight(m)+2,df.MsgWidth(m)+2,
                    df.NULL,null,null,
                    df.HASBORDER | df.SHADOW | df.SAVESELF,
                    allocator);
    const wnd = win.win;

    _ = win.sendTextMessage(msg.SETTEXT, @constCast(message), 0);
    if (df.cfg.mono == 0) {
        wnd.*.WindowColors[df.STD_COLOR][df.FG] = df.WHITE;
        wnd.*.WindowColors[df.STD_COLOR][df.BG] = df.GREEN;
        wnd.*.WindowColors[df.FRAME_COLOR][df.FG] = df.WHITE;
        wnd.*.WindowColors[df.FRAME_COLOR][df.BG] = df.GREEN;
    }
    _ = win.sendMessage(msg.SHOW_WINDOW, 0, 0);
    return win;
}

fn YesNoBoxProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (message) {
        df.CREATE_WINDOW => {
            wnd.*.Class = df.MESSAGEBOX;
            df.InitWindowColors(wnd);
            wnd.*.attrib = wnd.*.attrib & (~df.CONTROLBOX); // should use win.AddAttribute()
        },
        df.KEYBOARD => {
//            int c = tolower((int)p1);
//            if (c == 'y')
//                SendMessage(wnd, COMMAND, ID_OK, 0);
//            else if (c == 'n')
//                SendMessage(wnd, COMMAND, ID_CANCEL, 0);
//            break;
        },
        else => {
        }
    }
    return root.BaseWndProc(df.MESSAGEBOX, wnd, message, p1, p2);
}

fn MessageBoxProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (message) {
        df.CREATE_WINDOW => {
            wnd.*.Class = df.MESSAGEBOX;
            df.InitWindowColors(wnd);
            wnd.*.attrib = wnd.*.attrib & (~df.CONTROLBOX); // should use win.AddAttribute()
        },
        df.KEYBOARD => {
//            if (p1 == '\r' || p1 == ESC)
//                ReturnValue = (int)p1;
        },
        else => {
        }
    }
    return root.BaseWndProc(df.MESSAGEBOX, wnd, message, p1, p2);
}

fn ErrorBoxProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (message)    {
        df.CREATE_WINDOW => {
            wnd.*.Class = df.ERRORBOX;
            df.InitWindowColors(wnd);
        },
        df.KEYBOARD => {
//            if (p1 == '\r' || p1 == ESC)
//                ReturnValue = (int)p1;
        },
        else => {
        }
    }
    return root.BaseWndProc(df.ERRORBOX, wnd, message, p1, p2);
}
