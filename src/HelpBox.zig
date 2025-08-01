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

pub export fn HelpBoxProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (message) {
        df.CREATE_WINDOW => {
            return df.cHelpBoxProc(wnd, message, p1, p2);
//            CreateWindowMsg(wnd);
        },
        df.INITIATE_DIALOG => {
//            return df.cHelpBoxProc(wnd, message, p1, p2);
            df.ReadHelp(wnd);
            return root.BaseWndProc(df.HELPBOX, wnd, message, p1, p2);
        },
        else => {
            return df.cHelpBoxProc(wnd, message, p1, p2);
        }
    }
}

pub export fn zHelpBoxProc(wnd: df.WINDOW, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) callconv(.c) c_int {
    switch (message) {
        df.CREATE_WINDOW => {
            _ = df.cHelpBoxProc(wnd, message, p1, p2);
//            CreateWindowMsg(wnd);
        },
        df.INITIATE_DIALOG => {
            _ = df.cHelpBoxProc(wnd, message, p1, p2);
//            ReadHelp(wnd);
        },
        df.COMMAND => {
            if (p2 != 0) {
            } else {
                const rtn = df.cHelpBoxProc(wnd, message, p1, p2);
                if (rtn == df.TRUE)
                    return rtn;
//            if (CommandMsg(wnd, p1))
//                return TRUE;
            }
        },
        df.KEYBOARD => {
//            if (WindowMoving)
//                break;
//            if (KeyboardMsg(wnd, p1))
//                return TRUE;
        },
        df.CLOSE_WINDOW => {
            _ = df.cHelpBoxProc(wnd, message, p1, p2);
//            if (ThisHelp != NULL)
//                ThisHelp->hwnd = NULL;
//            Helping = FALSE;
        },
        else => {
        }
    }
    return root.BaseWndProc(df.HELPBOX, wnd, message, p1, p2);
}

// ----------- load the help text file ------------
//pub fn LoadHelpFile(fname:[]const u8) void {
//    if (root.global_allocator.dupe(u8, fname)) |f| {
//        HelpFileName = f;
//    } else |_| {
//    }
//    df.LoadHelpFile(@constCast(fname.ptr));
//}

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
