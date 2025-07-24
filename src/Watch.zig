const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

var tick:usize = 0;
const hands = [_][]const u8{" À ", " Ú ", " ¿ ", " Ù "};
const bo = "Í";

pub export fn WatchIconProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (message) {
        df.CREATE_WINDOW => {
            tick = 0;
            const rtn = root.DefaultWndProc(wnd, message, p1, p2);
            _ = df.SendMessage(wnd, df.CAPTURE_MOUSE, 0, 0);
            _ = df.SendMessage(wnd, df.HIDE_MOUSE, 0, 0);
            _ = df.SendMessage(wnd, df.CAPTURE_KEYBOARD, 0, 0);
            _ = df.SendMessage(wnd, df.CAPTURE_CLOCK, 0, 0);
            return rtn;
        },
        df.CLOCKTICK => {
            tick = tick + 1;
            tick = tick & 3; // the same as tick % 4 for positive number
            _ = df.SendMessage(wnd.*.PrevClock, message, p1, p2);
            // (fall through and paint)
            _ = df.SetStandardColor(wnd);
            df.writeline(wnd, @constCast(hands[tick].ptr), 1, 1, df.FALSE);
            return df.TRUE;
        },
        df.PAINT => {
            _ = df.SetStandardColor(wnd);
            df.writeline(wnd, @constCast(hands[tick].ptr), 1, 1, df.FALSE);
            return df.TRUE;
        },
        df.BORDER => {
            const rtn = root.DefaultWndProc(wnd, message, p1, p2);
            df.writeline(wnd, @constCast(bo.ptr), 2, 0, df.FALSE);
            return rtn;
        },
        df.MOUSE_MOVED => {
            _ = df.SendMessage(wnd, df.HIDE_WINDOW, 0, 0);
            _ = df.SendMessage(wnd, df.MOVE, p1, p2);
            _ = df.SendMessage(wnd, df.SHOW_WINDOW, 0, 0);
            return df.TRUE;
        },
        df.CLOSE_WINDOW => {
            _ = df.SendMessage(wnd, df.RELEASE_CLOCK, 0, 0);
            _ = df.SendMessage(wnd, df.RELEASE_MOUSE, 0, 0);
            _ = df.SendMessage(wnd, df.RELEASE_KEYBOARD, 0, 0);
            _ = df.SendMessage(wnd, df.SHOW_MOUSE, 0, 0);
        },
        else => {
        }
    }
    return root.DefaultWndProc(wnd, message, p1, p2);
}

pub fn WatchIcon() Window {
    var mx:c_int = 10;
    var my:c_int = 10;
    _ = df.SendMessage(null, df.CURRENT_MOUSE_CURSOR, @intCast(@intFromPtr(&mx)), @intCast(@intFromPtr(&my)));
    const win = Window.create (
                    df.BOX,
                    null,
                    mx, my, 3, 5,
                    null, null,
                    WatchIconProc,
                    df.VISIBLE | df.HASBORDER | df.SHADOW | df.SAVESELF,
                    root.global_allocator);
    return win;
}
