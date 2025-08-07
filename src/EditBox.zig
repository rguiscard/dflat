const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const search = @import("Search.zig");

// ----------- CREATE_WINDOW Message ----------
fn CreateWindowMsg(wnd:df.WINDOW) c_int {
    const rtn = root.BaseWndProc(df.EDITBOX, wnd, df.CREATE_WINDOW, 0, 0);
    wnd.*.MaxTextLength = df.MAXTEXTLEN+1;
    wnd.*.textlen = @intCast(df.EditBufLen(wnd));
    wnd.*.InsertMode = df.TRUE;
    if (df.isMultiLine(wnd)>0) {
        wnd.*.WordWrapMode = df.TRUE;
    }
    _ = df.SendMessage(wnd, df.CLEARTEXT, 0, 0);
    return rtn;
}

pub export fn EditBoxProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (message) {
        df.CREATE_WINDOW => {
            return CreateWindowMsg(wnd);
        },
        df.COMMAND => {
            if (CommandMsg(wnd, p1) > 0) {
                return df.TRUE;
            }
        },
        else => {
            return df.cEditBoxProc(wnd, message, p1, p2);
        }
    }
    return root.BaseWndProc(df.EDITBOX, wnd, message, p1, p2);
}

// ----------- COMMAND Message ----------
fn CommandMsg(wnd:df.WINDOW, p1:df.PARAM) c_int {
    switch (p1) {
        df.ID_SEARCH => {
            search.SearchText(wnd);
            return df.TRUE;
        },
        df.ID_REPLACE => {
            search.ReplaceText(wnd);
            return df.TRUE;
        },
        df.ID_SEARCHNEXT => {
            search.SearchNext(wnd);
            return df.TRUE;
        },
        else => {
            return df.EditBoxCommandMsg(wnd, p1);
        }
    }
}
