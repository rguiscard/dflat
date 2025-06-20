const std = @import("std");
const df = @import("ImportC.zig").df;
const command = @import("Commands.zig").Command;

// Handle DBOX from dflat
box: *df.DBOX,

/// `@This()` can be used to refer to this struct type. In files with fields, it is quite common to
/// name the type here, so it can be easily referenced by other declarations in this file.
const TopLevelFields = @This();

pub fn init(box: *df.DBOX) TopLevelFields {
    return .{
        .box = box,
    };
}

pub fn setCheckBox(self: *TopLevelFields, cmd: command) void {
    const c:c_uint = @intCast(@intFromEnum(cmd));
    df.SetCheckBox(self.box,  c);
}

pub fn checkBoxSetting(self: *TopLevelFields, cmd: command) bool {
    const c:c_uint = @intCast(@intFromEnum(cmd));
    return (df.CheckBoxSetting(self.box,  c) > 0);
}

pub fn getEditBoxText(self: *TopLevelFields, cmd: command) [*c]u8 {
    const c:c_uint = @intCast(@intFromEnum(cmd));
    return df.GetEditBoxText(self.box,  c);
}

pub fn deinit(self: *TopLevelFields) void {
    _ = self;
}
