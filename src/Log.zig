const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");

pub export fn LogProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    return root.DefaultWndProc(wnd, message, p1, p2);
}

pub fn MessageLog(wnd:df.WINDOW) void {
    var box = Dialogs.Log;
    var dbox = DialogBox.init(&box);
    if (dbox.create(wnd, true, LogProc)) {
//        if (CheckBoxSetting(&Log, ID_LOGGING))    {
//            log = fopen("DFLAT.LOG", "wt");
//            SetCommandToggle(&MainMenu, ID_LOG);
//        }
//        else if (log != NULL)    {
//            fclose(log);
//            log = NULL;
//            ClearCommandToggle(&MainMenu, ID_LOG);
//        }
    }
}
