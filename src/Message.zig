const std = @import("std");
const df = @import("ImportC.zig").df;
const Window = @import("Window.zig");

// ------------ initialize the message system ---------
pub fn init_messages() bool {
    return (df.init_messages() > 0);
}

// --------- send a message to a window -----------
pub fn SendMessage(wnd: Window, msg: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) c_int {
    return df.SendMessage(wnd.win, msg, p1, p2);
}

// ---- dispatch messages to the message proc function ----
pub fn dispatch_message() bool {
    return (df.dispatch_message() > 0);
}
