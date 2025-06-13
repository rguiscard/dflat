const std = @import("std");
const df = @import("ImportC.zig").df;

win: df.WINDOW,
title: ?[]const u8 = null,
allocator: std.mem.Allocator,

/// `@This()` can be used to refer to this struct type. In files with fields, it is quite common to
/// name the type here, so it can be easily referenced by other declarations in this file.
const TopLevelFields = @This();

pub fn init(wnd: df.WINDOW, allocator: std.mem.Allocator) TopLevelFields {
    return .{
        .win = wnd,
        .allocator = allocator,
    };
}

// This set with win.title and wnd.title
pub fn setTitle(self: *TopLevelFields, filename: []const u8) !void {
    if (self.title != null) {
        self.allocator.free(filename);
    }
    self.title = try self.allocator.dupe(u8, filename);

    self.win.*.extension = df.DFmalloc(filename.len+1);
    const ext:[*c]u8 = @ptrCast(self.win.*.extension);
    // wnd.extension is used to store filename.
    // it is also be used to compared already opened files.
    _ = df.strcpy(ext, filename.ptr);
}

pub fn sendMessage(self: *TopLevelFields, message: df.MESSAGE, p1: df.PARAM, p2: df.PARAM) isize {
    return df.SendMessage(self.win, message, p1, p2);
}

pub fn sendTextMessage(self: *TopLevelFields, message: df.MESSAGE, p1: []u8, p2: df.PARAM) isize {
    // message should only be df.SETTEXT ?
    const buf:[*c]u8 = p1.ptr;
    return df.SendMessage(self.win, message, @intCast(@intFromPtr(buf)), p2);
}

pub fn deinit(self: *TopLevelFields) void {
    self.allocator.free(self.title);
}
