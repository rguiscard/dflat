const std = @import("std");
const df = @import("ImportC.zig").df;

win: df.WINDOW,

/// `@This()` can be used to refer to this struct type. In files with fields, it is quite common to
/// name the type here, so it can be easily referenced by other declarations in this file.
const TopLevelFields = @This();

pub fn init(wnd: df.WINDOW) TopLevelFields {
    return .{
        .win = wnd,
    };
}
