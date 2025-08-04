const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");
const Dialogs = @import("Dialogs.zig");
const DialogBox = @import("DialogBox.zig");

//var FirstHelp:*df.helps = undefined;
//var ThisHelp:?*df.helps = undefined;

//var HelpFileName:[]const u8 = undefined;
//var Helping:bool = false;
//var stacked:isize = 0;

const MAXHEIGHT  = df.SCREENHEIGHT-10;
const MAXHELPKEYWORDS = 50; // --- maximum keywords in a window ---
const MAXHELPSTACK = 100;

// ------------- CREATE_WINDOW message ------------
fn CreateWindowMsg(wnd:df.WINDOW) void {
    df.Helping = df.TRUE;
    wnd.*.Class = df.HELPBOX;
    df.InitWindowColors(wnd);
    if (df.ThisHelp != null)
        df.ThisHelp.*.hwnd = wnd;
}

// ------------- COMMAND message ------------
fn CommandMsg(wnd:df.WINDOW, p1:df.PARAM) bool {
    switch (p1) {
        df.ID_PREV => {
            if (df.ThisHelp != null) {
                const prevhlp:usize = @intCast(df.ThisHelp.*.prevhlp);
                df.SelectHelp(wnd, df.FirstHelp+prevhlp, df.TRUE);
            }
            return true;
        },
        df.ID_NEXT => {
            if (df.ThisHelp != null) {
                const nexthlp:usize = @intCast(df.ThisHelp.*.nexthlp);
                df.SelectHelp(wnd, df.FirstHelp+nexthlp, df.TRUE);
            }
            return true;
        },
        df.ID_BACK => {
            if (df.stacked > 0) {
                df.stacked -= 1;
                const stacked:usize = @intCast(df.stacked);
                const helpstack:usize = @intCast(df.HelpStack[stacked]);
                df.SelectHelp(wnd, df.FirstHelp+helpstack, df.FALSE);
            }
            return true;
        },
        else => {
        }
    }
    return false;
}

pub export fn HelpBoxProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (message) {
        df.CREATE_WINDOW => {
            CreateWindowMsg(wnd);
        },
        df.INITIATE_DIALOG => {
            df.ReadHelp(wnd);
        },
        df.COMMAND => {
            if (p2 == 0) {
                if (CommandMsg(wnd, p1))
                    return df.TRUE;
            }
        },
        df.KEYBOARD => {
            if (df.WindowMoving == 0) {
                if (df.HelpBoxKeyboardMsg(wnd, p1) > 0)
                return df.TRUE;
            }
        },
        df.CLOSE_WINDOW => {
            if (df.ThisHelp != null)
                df.ThisHelp.*.hwnd = null;
            df.Helping = df.FALSE;
        },
        else => {
        }
    }
    return root.BaseWndProc(df.HELPBOX, wnd, message, p1, p2);
}

// ---- strip tildes from the help name ----
fn StripTildes(input: []const u8, buffer: *[30]u8) []const u8 {
    const tilde = '~';
    var i: usize = 0;

    for (input) |c| {
        if (c != tilde) {
            buffer[i] = c;
            i += 1;
        }
    }
    return buffer[0..i];
}

// ---------- display help text -----------
pub fn DisplayHelp(wnd:df.WINDOW, Help:[]const u8) c_int {
    var buffer:[30]u8 = undefined;
    var rtn = df.FALSE;

    @memset(&buffer, 0);

    if (df.Helping > 0)
        return df.TRUE;
    const FixedHelp = StripTildes(Help, &buffer);

    wnd.*.isHelping += 1;
    df.ThisHelp = df.FindHelp(@constCast(FixedHelp.ptr));
    if (df.ThisHelp) |thisHelp| {
        _ = thisHelp;
        df.helpfp = df.OpenHelpFile(&df.HelpFileName, "rb");
        if (df.helpfp) |_| {
            df.BuildHelpBox(wnd);
            df.DisableButton(&Dialogs.HelpBox, df.ID_BACK);
            // ------- display the help window -----
            var box = DialogBox.init(&Dialogs.HelpBox);
            _ = box.create(null, true, HelpBoxProc);
            df.free(Dialogs.HelpBox.dwnd.title);
            Dialogs.HelpBox.dwnd.title = null;
            _ = df.fclose(df.helpfp);
            df.helpfp = null;
            rtn = df.TRUE;
        }
    }
    wnd.*.isHelping -= 1;
    return rtn;
}
