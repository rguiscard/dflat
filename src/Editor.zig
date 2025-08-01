const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

pub export fn EditorProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    return df.cEditorProc(wnd, message, p1, p2);
}

// ------- Window processing module for EDITBOX class ------
//int EditorProc(WINDOW wnd, MESSAGE msg, PARAM p1, PARAM p2)
//{
//    switch (msg)    {
//                case KEYBOARD:
//            if (KeyboardMsg(wnd, p1, p2))
//                return TRUE;
//            break;
//                case SETTEXT:
//                        return SetTextMsg(wnd, (char *) p1);
//        default:
//            break;
//    }
//    return BaseWndProc(EDITOR, wnd, msg, p1, p2);
//}
