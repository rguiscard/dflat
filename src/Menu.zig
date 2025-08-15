const std = @import("std");
const df = @import("ImportC.zig").df;
const root = @import("root.zig");
const Window = @import("Window.zig");

fn FindCmd(mn:*df.MBAR, cmd:c_int) ?*df.PopDown {
    const mnu = mn.*.PullDown;
    for(mnu, 0..) |pulldown, idx| {
        if (pulldown.Title != null) {
            const pd = pulldown.Selections;
            for(pd, 0..) |selection, jdx| {
                if (selection.SelectionTitle != null) {
                    if (selection.ActionId == cmd) {
                        return @constCast(&mn.*.PullDown[idx].Selections[jdx]);
                    }
                }
            }
        }
    }
    return null;
}

//pub export fn GetCommandText(mn:*df.MBAR, cmd:c_int) [*c]u8 {
//    struct PopDown *pd = FindCmd(mn, cmd);
//    if (pd != NULL)
//        return pd->SelectionTitle;
//    return NULL;
//}

//pub export fn isCascadedCommand(mn:*df.MBAR, cmd:c_int) c_int {
//    struct PopDown *pd = FindCmd(mn, cmd);
//    if (pd != NULL)
//        return pd->Attrib & CASCADED;
//    return FALSE;
//}

pub export fn ActivateCommand(mn:*df.MBAR, cmd:c_int) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib = pulldown.*.Attrib & ~df.INACTIVE;
    }
}

pub export fn DeactivateCommand(mn:*df.MBAR, cmd:c_int) void {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        pulldown.*.Attrib = pulldown.*.Attrib | df.INACTIVE;
    }
}

pub export fn isActive(mn:*df.MBAR, cmd:c_int) c_int {
    const pd = FindCmd(mn, cmd);
    if (pd) |pulldown| {
        if (pulldown.*.Attrib & df.INACTIVE == 0) {
            return df.TRUE;
        }
    }
    return df.FALSE;
}

//pub export fn GetCommandToggle(mn:*df.MBAR, cmd:c_int) c_int {
//    struct PopDown *pd = FindCmd(mn, cmd);
//    if (pd != NULL)
//        return (pd->Attrib & CHECKED) != 0;
//    return FALSE;
//}

//pub export fn SetCommandToggle(mn:*df.MBAR, cmd:c_int) c_int {
//    struct PopDown *pd = FindCmd(mn, cmd);
//    if (pd != NULL)
//        pd->Attrib |= CHECKED;
//}

//pub export fn ClearCommandToggle(mn:*df.MBAR, cmd:c_int) void {
//    struct PopDown *pd = FindCmd(mn, cmd);
//    if (pd != NULL)
//        pd->Attrib &= ~CHECKED;
//}

//pub export fn InvertCommandToggle(mn:*df.MBAR, cmd:c_int) void {
//    struct PopDown *pd = FindCmd(mn, cmd);
//    if (pd != NULL)
//        pd->Attrib ^= CHECKED;
//}
